#include <inc/assert.h>
#include <inc/x86.h>
#include <kern/spinlock.h>
#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/monitor.h>

void sched_halt(void);

#ifndef VMM_GUEST
#include <vmm/vmx.h>
static int
vmxon() {
	int r;
	if(!thiscpu->is_vmx_root) {
		r = vmx_init_vmxon();
		if(r < 0) {
			cprintf("Error executing VMXON: %e\n", r);
			return r;
		}
		cprintf("VMXON\n");
	}
	return 0;
}
#endif

// Choose a user environment to run and run it.
void
sched_yield(void)
{
	struct Env *idle;
	//int i;
	// Implement simple round-robin scheduling.
	//
	// Search through 'envs' for an ENV_RUNNABLE environment in
	// circular fashion starting just after the env this CPU was
	// last running.  Switch to the first such environment found.
	//
	// If no envs are runnable, but the environment previously
	// running on this CPU is still ENV_RUNNING, it's okay to
	// choose that environment.
	//
	// Never choose an environment that's currently running on
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.
	idle = thiscpu->cpu_env;
	int i = 0;
	if(idle)
 		i = ENVX(thiscpu->cpu_env->env_id);
	int k = 0 ;
	while(k<NENV) {
		i = (i+1)%NENV;	
		if (envs[i].env_status == ENV_RUNNABLE) {
#ifndef VMM_GUEST
			if (envs[i].env_type == ENV_TYPE_GUEST) {
				// Cannot do this inside guest...
				// the environment doesn't have a clue that it is an environment.
				// Its an OS now.. :D
				if (!vmxon()) {
					if (curenv && curenv->env_status == ENV_RUNNING) {
						curenv->env_status = ENV_RUNNABLE;
    				}
 		    		curenv = &envs[i];
					curenv->env_status = ENV_RUNNING;
					curenv->env_runs++;
		    		vmx_vmrun(&envs[i]);
				}
			}
			else {
#endif
				env_run(&envs[i]);
#ifndef VMM_GUEST
			}
#endif
			return;
		}
		k++;
	}
	// LAB 4: Your code here.

	// sched_halt never returns
	if(idle && idle->env_status == ENV_RUNNING)
	{
#ifndef VMM_GUEST
		if (idle->env_type == ENV_TYPE_GUEST) {
			if (!vmxon()) {
				idle->env_runs++;
				vmx_vmrun(idle);
			}
		}
		else {
#endif
			env_run(idle);
		}
#ifndef VMM_GUEST
	}
#endif
	sched_halt();
}

// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.

void
sched_halt(void)
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
		while (1)
			monitor(NULL);
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
	lcr3(PADDR(boot_pml4e));

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
		"movq $0, %%rbp\n"
		"movq %0, %%rsp\n"
		"pushq $0\n"
		"pushq $0\n"
		"sti\n"
		"hlt\n"
		: : "a" (thiscpu->cpu_ts.ts_esp0));
}
