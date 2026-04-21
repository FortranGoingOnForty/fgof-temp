program test_atomic_write
  use fgof_temp, only : &
    FGOF_TEMP_OK, &
    atomic_write, &
    cleanup_temp, &
    make_temp_dir
  use fgof_temp_posix, only : path_exists_posix
  use fgof_temp_types, only : temp_resource, write_result
  implicit none

  type(temp_resource) :: parent_dir
  type(write_result) :: result_value
  character(len=:), allocatable :: target_path

  parent_dir = make_temp_dir()
  if (.not. parent_dir%created) error stop "parent temp directory should be created"

  target_path = parent_dir%path // "/config.txt"

  result_value = atomic_write(target_path, "alpha")
  if (.not. result_value%completed) error stop "atomic write should complete"
  if (.not. result_value%replaced) error stop "atomic write should report replace semantics"
  if (result_value%error_code /= FGOF_TEMP_OK) error stop "atomic write should report ok"
  if (.not. path_exists_posix(target_path)) error stop "atomic write should create the target file"
  if (len(result_value%staging_path) == 0) error stop "atomic write should record its staging path"
  if (path_exists_posix(result_value%staging_path)) error stop "staging path should not remain after successful replace"
  if (read_text_file(target_path) /= "alpha") error stop "atomic write should persist text exactly"

  result_value = atomic_write(target_path, "beta  ")
  if (.not. result_value%completed) error stop "repeat atomic write should complete"
  if (result_value%error_code /= FGOF_TEMP_OK) error stop "repeat atomic write should report ok"
  if (read_text_file(target_path) /= "beta  ") error stop "repeat atomic write should replace existing content exactly"

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

end program test_atomic_write
