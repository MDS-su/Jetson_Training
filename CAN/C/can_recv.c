#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <sys/ioctl.h>

int main() {
    int sock;
    struct sockaddr_can addr;
    struct ifreq ifr;
    struct can_frame frame;
    
    sock = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    strcpy(ifr.ifr_name, "can0");
    ioctl(sock, SIOCGIFINDEX, &ifr);
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;
    bind(sock, (struct sockaddr *)&addr, sizeof(addr));
    while (1) {
		read(sock, &frame, sizeof(struct can_frame));
		printf("수신 데이터: ID=%X, 데이터=", frame.can_id);
		for(int i=0; i<frame.can_dlc; i++){
			printf("%X", frame.data[i]);
		}
		printf("\n"); 
	}
    close(sock);
    return 0;
}