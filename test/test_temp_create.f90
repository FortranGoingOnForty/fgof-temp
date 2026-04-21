program test_temp_create
  use fgof_temp, only : &
    FGOF_TEMP_OK, &
    cleanup_temp, &
    make_temp_dir, &
    make_temp_file
  use fgof_temp_posix, only : is_directory_path_posix, path_exists_posix
  use fgof_temp_types, only : temp_resource
  implicit none

  type(temp_resource) :: file_resource
  type(temp_resource) :: dir_resource
  integer :: unit
  integer :: ios
  character(len=:), allocatable :: child_path

  file_resource = make_temp_file()
  if (.not. file_resource%created) error stop "temp file should be created"
  if (file_resource%directory) error stop "temp file should not be marked as a directory"
  if (.not. file_resource%owned) error stop "temp file should be owned"
  if (file_resource%error_code /= FGOF_TEMP_OK) error stop "temp file creation should report ok"
  if (.not. path_exists_posix(file_resource%path)) error stop "temp file path should exist"
  if (is_directory_path_posix(file_resource%path)) error stop "temp file path should not be a directory"

  open(newunit=unit, file=file_resource%path, status="old", action="readwrite", iostat=ios)
  if (ios /= 0) error stop "temp file should be openable"
  write(unit, "(a)", iostat=ios) "hello"
  if (ios /= 0) error stop "temp file should be writable"
  close(unit)

  call cleanup_temp(file_resource)
  if (file_resource%created) error stop "cleaned file resource should not stay marked created"
  if (file_resource%owned) error stop "cleaned file resource should not stay owned"
  if (file_resource%error_code /= FGOF_TEMP_OK) error stop "cleaned file resource should report ok"
  if (path_exists_posix(file_resource%path)) error stop "cleanup should remove the temp file"

  dir_resource = make_temp_dir()
  if (.not. dir_resource%created) error stop "temp directory should be created"
  if (.not. dir_resource%directory) error stop "temp directory should be marked as a directory"
  if (.not. dir_resource%owned) error stop "temp directory should be owned"
  if (dir_resource%error_code /= FGOF_TEMP_OK) error stop "temp directory creation should report ok"
  if (.not. path_exists_posix(dir_resource%path)) error stop "temp directory path should exist"
  if (.not. is_directory_path_posix(dir_resource%path)) error stop "temp directory path should be a directory"

  child_path = dir_resource%path // "/marker.txt"
  open(newunit=unit, file=child_path, status="replace", action="write", iostat=ios)
  if (ios /= 0) error stop "temp directory should allow file creation inside it"
  write(unit, "(a)", iostat=ios) "marker"
  if (ios /= 0) error stop "marker file should be writable"
  close(unit)

  open(newunit=unit, file=child_path, status="old", action="readwrite", iostat=ios)
  if (ios /= 0) error stop "marker file should be reopenable"
  close(unit, status="delete")

  call cleanup_temp(dir_resource)
  if (dir_resource%created) error stop "cleaned dir resource should not stay marked created"
  if (dir_resource%owned) error stop "cleaned dir resource should not stay owned"
  if (dir_resource%error_code /= FGOF_TEMP_OK) error stop "cleaned dir resource should report ok"
  if (path_exists_posix(dir_resource%path)) error stop "cleanup should remove the temp directory"
end program test_temp_create
