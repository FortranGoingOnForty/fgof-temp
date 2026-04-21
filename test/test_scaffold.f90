program test_scaffold
  use fgof_temp, only : &
    FGOF_TEMP_OK, &
    clear_temp_options, &
    clear_temp_resource, &
    temp_backend_name, &
    temp_error_name
  use fgof_temp_types, only : temp_options, temp_resource
  implicit none

  type(temp_options) :: options
  type(temp_resource) :: resource

  options = clear_temp_options()
  if (options%directory) error stop "temp options should default to file mode"
  if (.not. options%cleanup_on_close) error stop "temp options should default to cleanup on close"
  if (allocated(options%prefix)) error stop "temp options should not allocate prefix by default"
  if (allocated(options%suffix)) error stop "temp options should not allocate suffix by default"
  if (allocated(options%parent_dir)) error stop "temp options should not allocate parent_dir by default"

  resource = clear_temp_resource()
  if (resource%created) error stop "temp resource should start uncreated"
  if (resource%directory) error stop "temp resource should default to file mode"
  if (resource%owned) error stop "temp resource should start unowned"
  if (resource%error_code /= FGOF_TEMP_OK) error stop "temp resource should default to ok"
  if (resource%path /= "") error stop "temp resource should default to an empty path"
  if (resource%error_message /= "") error stop "temp resource should default to an empty message"

  if (temp_backend_name() /= "filesystem") error stop "backend name should describe the current scaffold"
  if (temp_error_name(FGOF_TEMP_OK) /= "ok") error stop "error helper should map ok"
  if (temp_error_name(10) /= "invalid-options") error stop "error helper should map invalid options"
  if (temp_error_name(999) /= "unknown") error stop "error helper should map unknown codes"
end program test_scaffold
