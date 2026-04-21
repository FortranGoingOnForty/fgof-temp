program test_temp_options
  use fgof_temp, only : &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    cleanup_temp, &
    clear_temp_options, &
    make_temp_dir, &
    make_temp_file
  use fgof_temp_types, only : temp_options, temp_resource
  implicit none

  type(temp_options) :: options
  type(temp_resource) :: parent_dir
  type(temp_resource) :: resource

  parent_dir = make_temp_dir()
  if (.not. parent_dir%created) error stop "parent temp directory should be created"

  options = clear_temp_options()
  options%prefix = "case-"
  options%suffix = ".txt"
  options%parent_dir = parent_dir%path
  options%cleanup_on_close = .false.

  resource = make_temp_file(options)
  if (.not. resource%created) error stop "temp file with options should be created"
  if (resource%error_code /= FGOF_TEMP_OK) error stop "temp file with options should report ok"
  if (resource%cleanup_on_close) error stop "resource should preserve cleanup_on_close option"
  if (.not. starts_with(resource%path, parent_dir%path // "/case-")) error stop "temp file should honor parent and prefix"
  if (.not. ends_with(resource%path, ".txt")) error stop "temp file should honor suffix"
  call cleanup_temp(resource)

  options = clear_temp_options()
  options%suffix = ".d"
  resource = make_temp_dir(options)
  if (resource%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "temp dir suffix should be rejected"

  options = clear_temp_options()
  options%prefix = "bad/name"
  resource = make_temp_file(options)
  if (resource%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "prefix with slash should be rejected"

  options = clear_temp_options()
  options%suffix = "bad/name"
  resource = make_temp_file(options)
  if (resource%error_code /= FGOF_TEMP_ERR_INVALID_OPTIONS) error stop "suffix with slash should be rejected"

  call cleanup_temp(parent_dir)

contains

  logical function starts_with(text, prefix) result(matches)
    character(len=*), intent(in) :: text
    character(len=*), intent(in) :: prefix

    if (len(text) < len(prefix)) then
      matches = .false.
      return
    end if

    matches = (text(:len(prefix)) == prefix)
  end function starts_with

  logical function ends_with(text, suffix) result(matches)
    character(len=*), intent(in) :: text
    character(len=*), intent(in) :: suffix
    integer :: offset

    if (len(text) < len(suffix)) then
      matches = .false.
      return
    end if

    offset = len(text) - len(suffix)
    matches = (text(offset + 1:) == suffix)
  end function ends_with

end program test_temp_options
