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

ALL_LIB 	:= src/lib_base.c src/lib_math.c src/lib_bit.c src/lib_string.c src/lib_table.c src/lib_io.c src/lib_os.c src/lib_package.c src/lib_debug.c src/lib_jit.c src/lib_ffi.c src/lib_buffer.c
ALL_LJ		:= $(wildcard src/lj_*.c)
BUILD_LIB   := src/lib_aux.c src/lib_base.c src/lib_bit.c src/lib_buffer.c src/lib_debug.c src/lib_math.c src/lib_string.c src/lib_table.c

HOST_CC 	:= cc
HOST_CFLAGS := -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -Isrc/ -DTARGET_OS_IPHONE=0

CC 			:= clang
CFLAGS 		:= 	-target x86_64-elf\
				-nostdinc\
				-std=gnu17\
				-Wno-duplicate-decl-specifier -Wno-unused-command-line-argument -Wno-unknown-attributes \
				-I../../inc/lj-libc -I../../inc -Isrc \
				-DLUAJIT_DISABLE_FFI -DLUAJIT_USE_SYSMALLOC -DLUAJIT_TARGET=LUAJIT_ARCH_X64 -DLUAJIT_OS=LUAJIT_OS_OTHER -DLUAJIT_DISABLE_JIT -DLUAJIT_DISABLE_FFI -DLUAJIT_NO_UNWIND -DTARGET_OS_IPHONE=0 -DLUAJIT_SECURITY_PRNG=0\
				-g\
				-mcmodel=kernel\
				-fno-omit-frame-pointer\
				-Wno-implicit-function-declaration

ALL_BUILDVM := $(wildcard src/host/buildvm*.c)


all: libluajit_luck.o

src/host/buildvm_arch.h: src/vm_x64.dasc
	$(LUA) dynasm/dynasm.lua -LN -D P64 -D NO_UNWIND -o $@ $<



buildvm.exe: src/host/buildvm_arch.h $(ALL_BUILDVM)
	$(HOST_CC) $(ALL_BUILDVM) $(HOST_CFLAGS) -Isrc/host/ -o $@

src/lj_vm.s: buildvm.exe
	./buildvm.exe -m elfasm -o $@

src/lj_bcdef.h: buildvm.exe
	./$< -m bcdef -o $@ $(ALL_LIB)

src/lj_ffdef.h: buildvm.exe
	./$< -m ffdef -o $@ $(ALL_LIB)

src/lj_libdef.h: buildvm.exe
	./$< -m libdef -o $@ $(ALL_LIB)

src/lj_recdef.h: buildvm.exe
	./$< -m recdef -o $@ $(ALL_LIB)

src/jit/vmdef.lua: buildvm.exe
	./$< -m vmdef -o $@ $(ALL_LIB)

src/lj_folddef.h: buildvm.exe src/lj_opt_fold.c
	./$< -m folddef -o $@ $<

src/lj_vm.o: src/lj_vm.s src/lj_bcdef.h src/lj_ffdef.h src/lj_libdef.h src/lj_recdef.h src/jit/vmdef.lua src/lj_folddef.h
	$(CC) -c $(CFLAGS) -o $@ $<

libluajit_luck.o: src/lj_vm.o $(ALL_LJ:.c=.o) $(BUILD_LIB:.c=.o)
	ld.lld -r -o $@ $^

%.o: %.c
	@/usr/bin/printf "\033[0;32m\033[1;35m[LuaJIT]\033[0m Compiling $<\033[0m"
	$(CC) -c $(CFLAGS) -o $@ $<
