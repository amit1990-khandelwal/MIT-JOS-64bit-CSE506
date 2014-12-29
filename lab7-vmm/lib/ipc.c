// User-level IPC library routines

#include <inc/lib.h>
#ifdef VMM_GUEST
#include <inc/vmx.h>
#endif

// Receive a value via IPC and return it.
// If 'pg' is nonnull, then any page sent by the sender will be mapped at
//	that address.
// If 'from_env_store' is nonnull, then store the IPC sender's envid in
//	*from_env_store.
// If 'perm_store' is nonnull, then store the IPC sender's page permission
//	in *perm_store (this is nonzero iff a page was successfully
//	transferred to 'pg').
// If the system call fails, then store 0 in *fromenv and *perm (if
//	they're nonnull) and return the error.
// Otherwise, return the value sent by the sender
//
// Hint:
//   Use 'thisenv' to discover the value and who sent it.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
	int r = 0;
	if(pg) {
		r = sys_ipc_recv(pg);
	}
	else {
		r = sys_ipc_recv((void*)KERNBASE);
	}
	if (r < 0) {
		*from_env_store =  (from_env_store != NULL) ? (envid_t)0 : *from_env_store;
		*perm_store = (perm_store != NULL) ? (int)0 : *perm_store;
		return r;
	}
	if(from_env_store) {
		*from_env_store = thisenv->env_ipc_from;
	}
	if(perm_store) {
		*perm_store = thisenv->env_ipc_perm;
	}
	return thisenv->env_ipc_value;
	// LAB 4: Your code here.
	//panic("ipc_recv not implemented");
}

// Send 'val' (and 'pg' with 'perm', if 'pg' is nonnull) to 'toenv'.
// This function keeps trying until it succeeds.
// It should panic() on any error other than -E_IPC_NOT_RECV.
//
// Hint:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
	int r = -E_IPC_NOT_RECV;
	while(r == -E_IPC_NOT_RECV) {
		if(pg) {
			r = sys_ipc_try_send(to_env,val,pg,perm);
		}
		else {
			r = sys_ipc_try_send(to_env, val, (void*)KERNBASE, perm);
		}
		sys_yield();
	}
	if (r != 0) {
		panic("something went wrong with sending the page");
	}
	// LAB 4: Your code here.
	//panic("ipc_send not implemented");
}

#ifdef VMM_GUEST

// Access to host IPC interface through VMCALL.
// Should behave similarly to ipc_recv, except replacing the system call with a vmcall.
int32_t
ipc_host_recv(void *pg) {
	// LAB 8: Your code here.
	uint64_t a1;
	uint64_t a2;
	uint64_t a3;
	uint64_t a4;
	uint64_t a5;
	int ret = 0;
	int num = VMX_VMCALL_IPCRECV;
	
	if(!pg)
		pg = (void*) KERNBASE;

	a1 = (uint64_t) pg;
	a2 = (uint64_t) 0;
	a3 = (uint64_t) 0;
	a4 = (uint64_t) 0;
	a5 = 0;

	//doubt : do we require what the site says ?

	asm volatile("vmcall\n"
			: "=a" (ret)
			: "a" (num),
			  "d" (a1),
			  "c" (a2),
			  "b" (a3),
			  "D" (a4),
			  "S" (a5)
			: "cc", "memory");

	if (ret > 0)
	    panic("vmcall %d returned %d (> 0) in ipc_host_send", num, ret);
	return ret;	

	//panic("ipc_recv not implemented in VM guest");
}

// Access to host IPC interface through VMCALL.
// Should behave similarly to ipc_send, except replacing the system call with a vmcall.
void
ipc_host_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
	// LAB 8: Your code here.
	uintptr_t addr;
	uint64_t a1;
	uint64_t a2;
	uint64_t a3;
	uint64_t a4;
	uint64_t a5;
	int ret = 0;
	int num = VMX_VMCALL_IPCSEND;
	
	if (!pg)
		pg = (void*)KERNBASE;
	
	a1 = (uint64_t)to_env;
	a2 = (uint64_t)val;
	a3 = (uint64_t)pg;
	a4 = (uint64_t)perm;
	a5 = 0;

	int r = -E_IPC_NOT_RECV;
        while(r == -E_IPC_NOT_RECV) { 
		asm volatile("vmcall\n"
			     : "=a" (ret)
			     : "a" (num),
			       "d" (a1),
			       "c" (a2),
			       "b" (a3),
			       "D" (a4),
			       "S" (a5)
			     : "cc", "memory");

		sys_yield();
	}
	if (r != 0) {
		panic("host_ipc_send : something went wrong with sending the page");
	}
	//panic("ipc_send not implemented in VM guest");
}

#endif

// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type == type)
			return envs[i].env_id;
	}
	return 0;
}
