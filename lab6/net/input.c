#include "ns.h"

extern union Nsipc nsipcbuf;

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";
	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.
	char buf[2048];
	int perm = PTE_U | PTE_P | PTE_W; //This is needed for page allocation from kern to user environment. (Remember no transfer can happen (that is sys_page_map)
	int len = 2047; // Buffer length
	int r = 0;
	while (1) {
		while ((r = sys_net_receive(buf, &len)) < 0) {
			sys_yield(); //This was neat.
		}
		// Get the page received from the PCI. (Don't use sys_page_map..use alloc)
		while ((r = sys_page_alloc(0, &nsipcbuf, perm)) < 0);
		nsipcbuf.pkt.jp_len = len;
		memmove(nsipcbuf.pkt.jp_data, buf, len);
		while ((r = sys_ipc_try_send(ns_envid, NSREQ_INPUT, &nsipcbuf, perm)) < 0);
	}
}
