program test_temp_close
  use fgof_temp, only : &
    FGOF_TEMP_OK, &
    clear_temp_options, &
    close_temp, &
    make_temp_file
  use fgof_temp_posix, only : path_exists_posix
  use fgof_temp_types, only : temp_options, temp_resource
  implicit none

  type(temp_options) :: options
  type(temp_resource) :: cleanup_file
  type(temp_resource) :: keep_file

  cleanup_file = make_temp_file()
  if (.not. cleanup_file%created) error stop "default close test should create a temp file"

  call close_temp(cleanup_file)
  if (cleanup_file%created) error stop "close_temp should delete default cleanup files"
  if (cleanup_file%owned) error stop "close_temp should clear ownership after cleanup"
  if (cleanup_file%error_code /= FGOF_TEMP_OK) error stop "close_temp should report ok after cleanup"
  if (path_exists_posix(cleanup_file%path)) error stop "close_temp should remove cleanup-on-close files"

  options = clear_temp_options()
  options%cleanup_on_close = .false.
  keep_file = make_temp_file(options)
  if (.not. keep_file%created) error stop "non-cleaning close test should create a temp file"
  if (.not. keep_file%owned) error stop "non-cleaning close test should start owned"

  call close_temp(keep_file)
  if (.not. keep_file%created) error stop "close_temp should leave non-cleaning resources marked created"
  if (keep_file%owned) error stop "close_temp should release ownership when cleanup_on_close is false"
  if (keep_file%error_code /= FGOF_TEMP_OK) error stop "close_temp should report ok when just releasing"
  if (.not. path_exists_posix(keep_file%path)) error stop "close_temp should not delete released files"

  call remove_file(keep_file%path)
contains

  subroutine remove_file(path)
    character(len=*), intent(in) :: path
    integer :: unit
    integer :: ios

    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="readwrite", iostat=ios)
    if (ios /= 0) error stop "manual file removal should reopen the released temp file"
    close(unit, status="delete", iostat=ios)
    if (ios /= 0) error stop "manual file removal should succeed"
  end subroutine remove_file
end program test_temp_close
