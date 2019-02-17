---
title:  MPI-IO
author: CSC Training
date:   2019-02
lang:   en
---


# MPI-IO

- Defines parallel operations for reading and writing files
    - I/O to only one file and/or to many files
    - Contiguous and non-contiguous I/O
    - Individual and collective I/O
    - Asynchronous I/O
- Potentially good performance, easy to use (compared to implementing the
  same patterns on your own)
- Portable programming *interface*
    - By default, binary *files* are not portable


# Basic concepts in MPI-IO

- File *handle*
    - data structure which is used for accessing the file
- File *pointer*
    - *position* in the file where to read or write
    - can be individual for all processes or shared between the processes
    - accessed through file handle or provided as an explicit offset from
      the beginning of the file
    - Here we do not use shared file pointers – performance is poor


# Basic concepts in MPI-IO

- File *view*
    - part of a parallel file which is visible to process
    - enables efficient noncontiguous access to file
- *Collective* and *independent* I/O
    - Collective = MPI coordinates the reads and writes of processes
    - Independent = no coordination by MPI, every man for himself


# Opening & Closing files

- All processes in a communicator open a file using

FIXME: missing function definition

- File is closed using `MPI_File_close(fhandle)`
- Can be combined with + in Fortran and | in C/C++


# File writing

- Write file at explicitly defined offsets
    - Thread-safe
    - The file pointer is neither used or incremented

FIXME: missing function definition


# Example: parallel write

```fortran
program output
use mpi
implicit none

integer :: err, i, myid, file, intsize
integer :: status(mpi_status_size)
integer, parameter :: count=100
integer, dimension(count) :: buf
integer(kind=mpi_offset_kind) :: disp

call mpi_init(err)
call mpi_comm_rank(mpi_comm_world, myid,&  err)

do i = 1, count
    buf(i) = myid * count + i
end do
```

- First process writes integers 1-100 to the beginning of the file, etc.


# Example: parallel write

```fortran
...

call mpi_file_open(mpi_comm_world, 'test', &
    mpi_mode_create + mpi_mode_wronly, & mpi_info_null, file, err)

intsize = sizeof(count)
disp = myid * count * intsize

call mpi_file_write_at(file, disp, buf, &
    count, mpi_integer, status, err)

call mpi_file_close(file, err)
call mpi_finalize(err)

end program output
```

- File offset determined explicitly


# File reading

- Read file at explicitly defined offsets
    - Thread-safe
    - The file pointer is neither referred or incremented

FIXME: missing function definition


# File pointer

- The file pointer can be updated with
- There are routines `MPI_File_write` and `MPI_File_read` that use the
  updated file handle (and not explicit offset)


# File writing

- Write file at individual file pointer:

`MPI_File_write(fhandle, buffer, count, datatype, status)`
  : `buffer`
    : buffer in memory which holds the data count number of elements to
      write

    `datatype`
    : datatype of elements to write

    `status`
    : status object

- Updates position of individual file pointer after writing
    - Not thread safe


# File reading

- Read file at individual file pointer

`MPI_File_read(fhandle, buffer, count, datatype, status)`
  : `buffer`
    : buffer in memory where to read the data

    `count`
    : number of elements to read

    `datatype`
    : datatype of elements to read

    `status`
    : similar to status in `MPI_Recv`, amount of data read can be
      determined by MPI_Get_count

- Updates position of individual file pointer after reading
    - Not thread safe


# Collective operations

- I/O can be performed *collectively* by all processes in a communicator
    - `MPI_File_read_all`
    - `MPI_File_write_all`
    - `MPI_File_read_at_all`
    - `MPI_File_write_at_all`
- Same parameters as in independent I/O functions (`MPI_File_read` etc.)


# Collective operations

- All processes in communicator that opened file must call function
    - Collective operation
- If all processes write or read, you should always use the collective
  reads and writes.
    - Performance much better than for individual functions
    - Even if each processor reads a non-contiguous segment, in total the
      read may be contiguous
    - Lots of optimizations implemented in the MPI libraries


# Non-blocking MPI-IO

- Non-blocking independent I/O is similar to non-blocking send/recv
  routines
    - `MPI_File_iread(_at)(_all)` /
      `MPI_File_iwrite(_at)(_all)`
- Wait for completion using `MPI_Test`, `MPI_Wait`, etc.
- Can be used to overlap I/O with computation:

FIXME: missing figure


# Non-contiguous data access with MPI-IO {.section}


# File view

- By default, file is treated as consisting of bytes, and process can
  access (read or write) any byte in the file
- The *file view* defines which portion of a file is visible to a process
- A file view consists of three components
    - displacement: number of bytes to skip from the beginning of file
    - etype: type of data accessed, defines unit for offsets
    - filetype: portion of file visible to a process


# File view

`MPI_File_set_view(fhandle, disp, etype, filetype, datarep, info)`
  : `disp`
    : Offset from beginning of file. Always in bytes

    `etype`
    : Basic MPI type or user defined type
    : Basic unit of data access

    `filetype`
    : Same type as etype or user defined type constructed of etype

    `datarep`
    : Data representation (can be adjusted for portability) "native": store
      in same format as in memory

    `info`
    : Hints for implementation that can improve performance
      `MPI_INFO_NULL`: No hints

# File view

- The values for `datarep` and the extents of `etype` must be identical on
  all processes in the group; values for `disp`, `filetype`, and `info` may
  vary.
- The datatypes passed in must be committed.


# File view for non-contiguous data

- Each process has to access small pieces of data scattered throughout
  a file
- Very expensive if implemented with separate reads/writes
- Use file type to implement the non-contiguous access

FIXME: missing figure


# File view for non-contiguous data

```fortran
...
integer, dimension(2,2) :: array
...
call mpi_type_create_subarray(2, sizes, subsizes, starts, mpi_integer, &
     mpi_order_c, filetype, err)
call mpi_type_commit(filetype)

disp = 0
call mpi_file_set_view(file, disp, mpi_integer, filetype, 'native', &
     mpi_info_null, err)

call mpi_file_write_all(file, buffer, count, mpi_integer, status, err)
```

FIXME: missing figure

- Collective write can be over hundred times faster than the individual
  for large arrays!


# Common mistakes with MPI I/O

- Not defining file offsets as `MPI_Offset` in C and integer
  (`kind=MPI_OFFSET_KIND`) in Fortran
- In Fortran, passing the offset or displacement directly as a constant
  (e.g. "0")
    - It has to be stored and passed as a variable of type
      `integer(MPI_OFFSET_KIND)`


# Performance do's and don'ts

- Use collective I/O routines
- Remember to use the correct striping for each file size
    - Striping can also be set in the `MPI_Info` parameter using the
      `MPI_Info_set` function:
      `MPI_Info_set(info, "striping_factor", "20")`
    - Optimal value system dependent, may be beneficial to benchmark
- Minimize metadata operations


# Summary

- MPI-IO: MPI library automatically handles all communication needed
  for parallel I/O access
- File views enable non-contiguous access patterns
- Collective I/O can enable the actual disk access to remain contiguous