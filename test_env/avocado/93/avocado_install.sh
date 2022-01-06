#! /bin/bash

entry=`dirname $0`
cd $entry

yum install -y python36.x86_64
yum install -y python36-pip.noarch

pip3 install -U ./pip-*.whl

find /usr/local -name "avocado*" | xargs rm -rf

###########
/usr/local/bin/pip3 install -U ./setuptools-*.whl
/usr/local/bin/pip3 install -U ./avocado_framework-*.whl

/usr/local/bin/pip3 install -U  ./MarkupSafe-*.whl
/usr/local/bin/pip3 install -U  ./Jinja2-*.whl
/usr/local/bin/pip3 install -U  ./avocado_framework_plugin_result_html-*.whl
/usr/local/bin/pip3 install -U  ./avocado_framework_plugin_result_upload-*.whl

#####
/usr/local/bin/pip3 install -U PyYAML-*.whl
/usr/local/bin/pip3 install -U avocado_framework_plugin_varianter_yaml_to_mux-*.whl

