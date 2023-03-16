# Copyright (C) 2023 Amrit Bhogal
#
# This file is part of LuaJIT.
#
# LuaJIT is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# LuaJIT is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LuaJIT.  If not, see <http://www.gnu.org/licenses/>.

# old shell script
# set -ex

# cd extern/luajit/src

# DASM=../dynasn/dynasm.lua
# ALL_LIB="lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c lib_buffer.c"

# gcc host/minilua.c -o minilua.exe -lm

# ./minilua.exe ../dynasm/dynasm.lua -LN -D P64 -D NO_UNWIND -o host/buildvm_arch.h vm_x64.dasc

# gcc host/buildvm*.c -o buildvm.exe -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -I. -DTARGET_OS_IPHONE=0

# ./buildvm.exe -m elfasm -o lj_vm.s
# ./buildvm.exe -m bcdef -o lj_bcdef.h $ALL_LIB
# ./buildvm.exe -m ffdef -o lj_ffdef.h $ALL_LIB
# ./buildvm.exe -m libdef -o lj_libdef.h $ALL_LIB
# ./buildvm.exe -m recdef -o lj_recdef.h $ALL_LIB
# ./buildvm.exe -m vmdef -o jit/vmdef.lua $ALL_LIB
# ./buildvm.exe -m folddef -o lj_folddef.h lj_opt_fold.c

# LJCOMPILE="clang -target x86_64-elf -nostdinc -Wno-duplicate-decl-specifier -Wno-unused-command-line-argument -Wno-unknown-attributes -I../../../inc -I../../../inc/lj-libc -DLUAJIT_DISABLE_FFI -DLUAJIT_USE_SYSMALLOC -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -I. -DTARGET_OS_IPHONE=0 -DLUAJIT_SECURITY_PRNG=0 -g -mcmodel=kernel -fno-omit-frame-pointer"

# rm -f lj_*.o lib_*.o

# $LJCOMPILE -c -o lj_vm.o lj_vm.s

# for f in lj_*.c lib_aux.c lib_base.c lib_bit.c lib_buffer.c lib_debug.c lib_math.c lib_string.c lib_table.c; do
#     $LJCOMPILE -c $f
# done

# ld.lld -r -o libluajit_luck.o lj_*.o lib_*.o

LUA 		:= luajit

ALL_LIB 	:= $(wildcard src/lib_*.c)
ALL_LJ		:= $(wildcard src/lj_*.c)

HOST_CC 	:= clang
HOST_CFLAGS := -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -Isrc/ -DTARGET_OS_IPHONE=0

CC 			:= clang
CFLAGS 		:= -target x86_64-elf -nostdinc -Wno-duplicate-decl-specifier -Wno-unused-command-line-argument -Wno-unknown-attributes -Iinc -Iinc/lj-libc -DLUAJIT_DISABLE_FFI -DLUAJIT_USE_SYSMALLOC -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -Isrc -DTARGET_OS_IPHONE=0 -DLUAJIT_SECURITY_PRNG=0 -g -mcmodel=kernel -fno-omit-frame-pointer

ALL_BUILDVM := $(wildcard src/host/buildvm*.c)


all: libluajit_luck.o

src/host/buildvm_arch.h: src/vm_x64.dasc
	$(LUA) dynasm/dynasm.lua -LN -D P64 -D NO_UNWIND -o $@ $<

buildvm.exe: $(patsubst src/host/%.c,src/host/%.o,$(ALL_BUILDVM))
	$(HOST_CC) $^ -o $@

src/host/%.o: src/host/%.c
	$(HOST_CC) $(HOST_CFLAGS) -c -o $@ $<

src/lj_vm.s: buildvm.exe
	./$< -m elfasm -o $@

src/lj_bcdef.h: buildvm.exe
	./$< -m bcdef -o $@ $(ALL_LIB)

src/lj_ffdef.h: buildvm.exe
	./$< -m ffdef -o $@ $(ALL_LIB)

src/lj_libdef.h: buildvm.exe
	./$< -m libdef -o $@ $(ALL_LIB)

src/lj_recdef.h: buildvm
	./$< -m recdef -o $@ $(ALL_LIB)

src/jit/vmdef.lua: buildvm.exe
	./$< -m vmdef -o $@ $(ALL_LIB)

src/lj_folddef.h: buildvm.exe src/lj_opt_fold.c
	./$< -m folddef -o $@ $<

src/lj_vm.o: src/lj_vm.s
	$(CC) -c $(CFLAGS) -o $@ $<

libluajit_luck.o: src/lj_vm.o $(ALL_LJ:.c=.o) $(ALL_LIB:.c=.o)
	ld.lld -r -o $@ $^

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
