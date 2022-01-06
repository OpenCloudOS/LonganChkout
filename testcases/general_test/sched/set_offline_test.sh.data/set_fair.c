#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <error.h>

int main(int argc, char *argv[])
{
	int pid;
	int ecode = 0;;
	struct sched_param param;
	if (argc < 2) {
		ecode = -1;
		goto out;
	}
	pid = atoi(argv[1]);
	if (!pid || pid == 1) {
		ecode = -1;
		goto out;
	}

	param.sched_priority = 0;
	ecode = sched_setscheduler(pid, SCHED_OTHER, &param);
out:
	return ecode;
}
