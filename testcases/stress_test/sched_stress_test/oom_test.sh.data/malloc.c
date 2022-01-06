#include <malloc.h>

void main() {
        int *p;

while (1) {
        p = (int *)malloc(sizeof(*p) * 1024);
        if (p == NULL) {
                printf("malloc failed\n");
                return;
        }
        sleep(1);
}
}
