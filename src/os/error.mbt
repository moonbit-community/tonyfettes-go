///|
pub(all) suberror Invalid

///|
pub(all) suberror Permission

///|
pub(all) suberror Exist

///|
pub(all) suberror NotExist

///|
pub(all) suberror Closed

///|
pub(all) suberror NoDeadline

///|
pub(all) suberror DeadlineExceeded

///|
pub fn is_exist(err : Error) -> Bool {
  match err {
    Exist => true
    _ => false
  }
}
