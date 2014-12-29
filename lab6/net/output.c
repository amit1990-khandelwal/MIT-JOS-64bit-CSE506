#include "ns.h"
#include <inc/string.h>
extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	int r = 0;
	while (1) {
		r = sys_ipc_recv(&nsipcbuf);
		// check if the request is for transmitting by checking the envid and value. (this process is forked from testoutput
		if ((thisenv->env_ipc_from != ns_envid) ||(thisenv->env_ipc_value != NSREQ_OUTPUT)) {
			continue;
		}
		while ((r = sys_net_transmit(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) < 0);		
    }
}
