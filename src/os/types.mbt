///|
/// A FileMode represents a file's mode and permission bits.
/// The bits have the same definition on all systems, so that
/// information about files can be moved from one system
/// to another portably. Not all bits apply to all systems.
/// The only required bit is [ModeDir] for directories.
pub typealias @fs.FileMode
