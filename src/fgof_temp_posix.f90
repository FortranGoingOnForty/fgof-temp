module fgof_temp_posix
  use iso_c_binding, only : c_char, c_int, c_null_char
  implicit none
  private

  integer, parameter :: PATH_BUFFER_LEN = 4096

  public :: create_temp_dir_posix
  public :: create_temp_file_posix
  public :: from_c_string
  public :: is_directory_path_posix
  public :: path_exists_posix
  public :: remove_temp_path_posix
  public :: to_c_string

  interface
    function fgof_temp_create_file(parent, prefix, suffix, path, path_len, sys_errno) bind(C, name="fgof_temp_create_file")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: parent(*)
      character(kind=c_char), intent(in) :: prefix(*)
      character(kind=c_char), intent(in) :: suffix(*)
      character(kind=c_char), intent(out) :: path(*)
      integer(c_int), value :: path_len
      integer(c_int), intent(out) :: sys_errno
      integer(c_int) :: fgof_temp_create_file
    end function fgof_temp_create_file

    function fgof_temp_create_dir(parent, prefix, path, path_len, sys_errno) bind(C, name="fgof_temp_create_dir")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: parent(*)
      character(kind=c_char), intent(in) :: prefix(*)
      character(kind=c_char), intent(out) :: path(*)
      integer(c_int), value :: path_len
      integer(c_int), intent(out) :: sys_errno
      integer(c_int) :: fgof_temp_create_dir
    end function fgof_temp_create_dir

    function fgof_temp_remove_path(path, directory, sys_errno) bind(C, name="fgof_temp_remove_path")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int), value :: directory
      integer(c_int), intent(out) :: sys_errno
      integer(c_int) :: fgof_temp_remove_path
    end function fgof_temp_remove_path

    function fgof_temp_path_exists(path) bind(C, name="fgof_temp_path_exists")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int) :: fgof_temp_path_exists
    end function fgof_temp_path_exists

    function fgof_temp_is_directory(path) bind(C, name="fgof_temp_is_directory")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int) :: fgof_temp_is_directory
    end function fgof_temp_is_directory
  end interface

contains

  logical function create_temp_file_posix(parent_dir, prefix, suffix, path, sys_errno) result(success)
    character(len=*), intent(in) :: parent_dir
    character(len=*), intent(in) :: prefix
    character(len=*), intent(in) :: suffix
    character(len=:), allocatable, intent(out) :: path
    integer, intent(out) :: sys_errno
    character(kind=c_char), allocatable :: c_parent(:)
    character(kind=c_char), allocatable :: c_prefix(:)
    character(kind=c_char), allocatable :: c_suffix(:)
    character(kind=c_char) :: c_path(PATH_BUFFER_LEN)
    integer(c_int) :: c_errno

    c_parent = to_c_string(parent_dir)
    c_prefix = to_c_string(prefix)
    c_suffix = to_c_string(suffix)
    c_path = c_null_char

    success = (fgof_temp_create_file(c_parent, c_prefix, c_suffix, c_path, int(PATH_BUFFER_LEN, c_int), c_errno) /= 0_c_int)
    sys_errno = int(c_errno)
    if (success) then
      path = from_c_string(c_path)
    else
      path = ""
    end if
  end function create_temp_file_posix

  logical function create_temp_dir_posix(parent_dir, prefix, path, sys_errno) result(success)
    character(len=*), intent(in) :: parent_dir
    character(len=*), intent(in) :: prefix
    character(len=:), allocatable, intent(out) :: path
    integer, intent(out) :: sys_errno
    character(kind=c_char), allocatable :: c_parent(:)
    character(kind=c_char), allocatable :: c_prefix(:)
    character(kind=c_char) :: c_path(PATH_BUFFER_LEN)
    integer(c_int) :: c_errno

    c_parent = to_c_string(parent_dir)
    c_prefix = to_c_string(prefix)
    c_path = c_null_char

    success = (fgof_temp_create_dir(c_parent, c_prefix, c_path, int(PATH_BUFFER_LEN, c_int), c_errno) /= 0_c_int)
    sys_errno = int(c_errno)
    if (success) then
      path = from_c_string(c_path)
    else
      path = ""
    end if
  end function create_temp_dir_posix

  logical function remove_temp_path_posix(path, directory, sys_errno) result(success)
    character(len=*), intent(in) :: path
    logical, intent(in) :: directory
    integer, intent(out) :: sys_errno
    character(kind=c_char), allocatable :: c_path(:)
    integer(c_int) :: c_errno
    integer(c_int) :: c_directory

    c_path = to_c_string(path)
    if (directory) then
      c_directory = 1_c_int
    else
      c_directory = 0_c_int
    end if

    success = (fgof_temp_remove_path(c_path, c_directory, c_errno) /= 0_c_int)
    sys_errno = int(c_errno)
  end function remove_temp_path_posix

  logical function path_exists_posix(path) result(success)
    character(len=*), intent(in) :: path
    character(kind=c_char), allocatable :: c_path(:)

    c_path = to_c_string(path)
    success = (fgof_temp_path_exists(c_path) /= 0_c_int)
  end function path_exists_posix

  logical function is_directory_path_posix(path) result(success)
    character(len=*), intent(in) :: path
    character(kind=c_char), allocatable :: c_path(:)

    c_path = to_c_string(path)
    success = (fgof_temp_is_directory(c_path) /= 0_c_int)
  end function is_directory_path_posix

  function to_c_string(str) result(buf)
    character(len=*), intent(in) :: str
    character(kind=c_char), allocatable :: buf(:)
    integer :: n
    integer :: i

    n = len(str)
    allocate(buf(0:n))
    do i = 1, n
      buf(i - 1) = str(i:i)
    end do
    buf(n) = c_null_char
  end function to_c_string

  function from_c_string(buf) result(str)
    character(kind=c_char), intent(in) :: buf(*)
    character(len=:), allocatable :: str
    integer :: n
    integer :: i

    n = 0
    do while (buf(n + 1) /= c_null_char)
      n = n + 1
    end do

    allocate(character(len=n) :: str)
    do i = 1, n
      str(i:i) = buf(i)
    end do
  end function from_c_string

end module fgof_temp_posix
