program atomic_write_demo
  use fgof_temp, only : atomic_write, cleanup_temp, make_temp_dir
  use fgof_temp_types, only : temp_resource, write_result
  implicit none

  type(temp_resource) :: dir_resource
  type(write_result) :: result_value
  character(len=:), allocatable :: path

  dir_resource = make_temp_dir()
  path = dir_resource%path // "/state.txt"

  result_value = atomic_write(path, "ready")
  if (.not. result_value%completed) stop 1

  print *, read_text_file(path)
  call cleanup_temp(dir_resource)
contains

  function read_text_file(path) result(text)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: text
    integer :: unit
    integer :: ios
    integer(kind=8) :: file_size

    inquire(file=path, size=file_size, iostat=ios)
    if (ios /= 0) stop 1

    allocate(character(len=int(file_size)) :: text)
    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="read", iostat=ios)
    if (ios /= 0) stop 1

    if (file_size > 0) then
      read(unit, iostat=ios) text
      if (ios /= 0) stop 1
    end if

    close(unit)
  end function read_text_file
end program atomic_write_demo
