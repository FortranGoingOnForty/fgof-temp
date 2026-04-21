program test_replace_file
  use fgof_temp, only : &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    atomic_write, &
    cleanup_temp, &
    make_temp_dir, &
    make_temp_file, &
    replace_file
  use fgof_temp_posix, only : path_exists_posix
  use fgof_temp_types, only : temp_resource, write_result
  implicit none

  type(temp_resource) :: parent_dir
  type(temp_resource) :: source_file
  type(write_result) :: result_value
  character(len=:), allocatable :: destination_path

  parent_dir = make_temp_dir()
  if (.not. parent_dir%created) error stop "parent temp directory should be created"

  source_file = make_temp_file()
  if (.not. source_file%created) error stop "source temp file should be created"

  result_value = atomic_write(source_file%path, "new payload")
  if (.not. result_value%completed) error stop "source temp file should be writable"

  destination_path = parent_dir%path // "/final.txt"
  result_value = atomic_write(destination_path, "old payload")
  if (.not. result_value%completed) error stop "destination seed write should complete"

  result_value = replace_file(source_file%path, destination_path)
  if (.not. result_value%completed) error stop "replace_file should complete"
  if (.not. result_value%replaced) error stop "replace_file should report replacement"
  if (result_value%error_code /= FGOF_TEMP_OK) error stop "replace_file should report ok"
  if (path_exists_posix(source_file%path)) error stop "replace_file should consume the source path"
  if (read_text_file(destination_path) /= "new payload") error stop "replace_file should replace destination content"

  result_value = replace_file("", destination_path)
  if (result_value%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "replace_file should reject empty source paths"

  call cleanup_temp(parent_dir)

contains

  function read_text_file(path) result(text)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: text
    integer :: unit
    integer :: ios
    integer(kind=8) :: file_size

    inquire(file=path, size=file_size, iostat=ios)
    if (ios /= 0) error stop "file size inquiry should succeed"

    allocate(character(len=int(file_size)) :: text)

    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="read", iostat=ios)
    if (ios /= 0) error stop "text file should be readable"

    if (file_size > 0) then
      read(unit, iostat=ios) text
      if (ios /= 0) error stop "text file should read cleanly"
    end if

    close(unit)
  end function read_text_file

end program test_replace_file
