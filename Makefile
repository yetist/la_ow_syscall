KERNELRELEASE	   ?= `uname -r`
KERNEL_DIR	   ?= /lib/modules/$(KERNELRELEASE)/build
PWD		   := $(shell pwd)
obj-m		   := la_ow_syscall.o
la_ow_syscall-objs := fsstat.o la_ow_syscall_main.o signal.o
ccflags-y          := $(call cc-option,-mno-relax) $(call cc-option,-Wa$(comma)-mno-relax)

.PHONY: all install clean
.PHONY: install-all
.PHONY: modprobe la_ow_syscall

# we don't control the .ko file dependencies, as it is done by kernel
# makefiles. therefore la_ow_syscall.ko is a phony target actually
.PHONY: la_ow_syscall.ko

all: la_ow_syscall.ko
la_ow_syscall: la_ow_syscall.ko
la_ow_syscall.ko:
	@echo "Building la_ow_syscall driver..."
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

$(obj)/ksym_addr.h: System.map
	@$(kecho) '  GEN     $@'
	$(Q)grep ' sys_call_table$$' $< >/dev/null
	$(Q)grep ' kallsyms_lookup_name$$' $< >/dev/null
	$(Q)echo "#define LAOWSYS_SYS_CALL_TABLE_ADDR 0x$$(grep ' sys_call_table$$' $< | cut -d ' ' -f 1)" > $@
	$(Q)echo "#define LAOWSYS_KALLSYMS_LOOKUP_NAME_ADDR 0x$$(grep ' kallsyms_lookup_name$$' $< | cut -d ' ' -f 1)" >> $@

$(obj)/$(la_ow_syscall-y): $(obj)/ksym_addr.h

install-all: install
install:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules_install

clean:
	rm -f *~
	rm -f Module.symvers Module.markers modules.order
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean

modprobe: la_ow_syscall.ko
	chmod a+r la_ow_syscall.ko
	sudo modprobe videodev
	-sudo rmmod la_ow_syscall
	sudo insmod ./la_ow_syscall.ko $(MODULE_OPTIONS)
