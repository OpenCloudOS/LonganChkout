#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <error.h>

#define SCHED_OFFLINE	7

int main(int argc, char *argv[])
{
	int pid,i=0;
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


	while(1)
	{
		if(i==0)
		{
			ecode = sched_setscheduler(pid, SCHED_OFFLINE, &param);
			i=1;
		}
		else
		{
			ecode = sched_setscheduler(pid, SCHED_OTHER, &param);
			i=0;
		}

	}
out:
	return ecode;
}
