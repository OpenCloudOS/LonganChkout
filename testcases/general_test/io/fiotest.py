#!/usr/bin/env python3

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See LICENSE for more details.
#
# Copyright: 2016 Red Hat, Inc.
# Author: Amador Pahim <apahim@redhat.com>
#
# Based on code by Randy Dunlap <rdunlap@xenotime.net>
#   copyright 2006 Randy Dunlap <rdunlap@xenotime.net>
#   https://github.com/autotest/autotest-client-tests/tree/master/fio

"""
FIO Test
"""

import os

from avocado import Test
from avocado.utils import archive
from avocado.utils import build
from avocado.utils import process, distro
from avocado.utils.partition import Partition
from avocado.utils.software_manager import SoftwareManager
from avocado.utils.partition import PartitionError


class FioTest(Test):

    """
    fio is an I/O tool meant to be used both for benchmark and
    stress/hardware verification.

    :see: http://freecode.com/projects/fio

    :param fio_tarbal: name of the tarbal of fio suite located in deps path
    :param fio_job: config defining set of executed tests located in deps path
    """


    def jobSetUp(self, arg, default_val):
        val = self.params.get(arg, default=default_val)
        cmd = "sed -i -e s/^%s=.*/%s=%s/ %s" % (arg, arg, val, self.get_data(self.job_file))
        process.system(cmd)
        self.job_name = "%s-%s" % (self.job_name, val)


    def setUp(self):
        """
        Build 'fio'.
        """
        #default_url = "http://brick.kernel.dk/snaps/fio-2.1.10.tar.gz"
        #url = self.params.get('fio_tool_url', default=default_url)
        self.disk = self.params.get('disk', default=None)
        self.dirs = self.params.get('dir', default=self.workdir)
        self.fstype = self.params.get('fs', default=None)
        tarball = self.get_data("fio-3.20.tar.gz")
        archive.extract(tarball, self.teststmpdir)
        fio_version = os.path.basename(tarball.split('.tar.')[0])
        self.sourcedir = os.path.join(self.teststmpdir, fio_version)
        build.make(self.sourcedir)

        smm = SoftwareManager()

        if self.fstype is not None:
            self.part_obj = Partition(self.disk, mountpoint=self.dirs)
            self.log.info("Unmounting disk/dir before creating file system")
            self.part_obj.unmount()
            self.log.info("creating file system")
            self.part_obj.mkfs(self.fstype)
            self.log.info("Mounting disk %s on directory %s",
                          self.disk, self.dirs)
            try:
                self.part_obj.mount()
            except PartitionError:
                self.fail("Mounting disk %s on directory %s failed"
                          % (self.disk, self.dirs))
            self.fio_file = 'fiotest-image'
        else:
            self.fio_file = self.disk
            self.dirs = ''

        self.job_file = self.params.get('fio_job', default='fio-perf.job')
        self.job_name = 'fio-perf'
        self.jobSetUp("ioengine", "psync")
        self.jobSetUp("direct", "0")
        self.jobSetUp("iodepth", "1")
        self.jobSetUp("rw", "rw")
        self.jobSetUp("rwmixread", "50")
        self.jobSetUp("rwmixwrite", "50")
        self.jobSetUp("bs", "4k")


    def test(self):
        """
        Execute 'fio' with appropriate parameters.
        """
        self.log.info("Test will run on %s", self.dirs)
        cmd = "%s/fio %s %s --filename=%s --output-format=json --output=/tmp/%s" % (self.sourcedir,
                            self.get_data(self.job_file),
                            self.dirs,
                            self.fio_file,
                            "%s.json" % self.job_name)
        process.system(cmd)

    def tearDown(self):
        '''
        Cleanup of disk used to perform this test
        '''
        if self.fstype is not None:
            self.log.info("Unmounting directory %s", self.dirs)
            self.part_obj.unmount()
        else:
            return

        self.log.info("Removing the filesystem created on %s", self.disk)
        delete_fs = "dd if=/dev/zero bs=512 count=512 of=%s" % self.disk
        if process.system(delete_fs, shell=True, ignore_status=True):
            self.fail("Failed to delete filesystem on %s", self.disk)
        if os.path.exists(self.fio_file):
            os.remove(self.fio_file)



