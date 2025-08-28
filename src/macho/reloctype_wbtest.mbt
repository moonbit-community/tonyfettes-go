///|
test "RelocTypeGeneric to_int" {
  assert_eq(RelocTypeGeneric::Vanilla.to_int(), 0)
  assert_eq(RelocTypeGeneric::Pair.to_int(), 1)
  assert_eq(RelocTypeGeneric::Sectdiff.to_int(), 2)
  assert_eq(RelocTypeGeneric::PbLaPtr.to_int(), 3)
  assert_eq(RelocTypeGeneric::LocalSectdiff.to_int(), 4)
  assert_eq(RelocTypeGeneric::Tlv.to_int(), 5)
}

///|
test "RelocTypeGeneric from_int valid" {
  match RelocTypeGeneric::from_int(0) {
    Some(Vanilla) => ()
    _ => fail("Expected Vanilla")
  }
  match RelocTypeGeneric::from_int(1) {
    Some(Pair) => ()
    _ => fail("Expected Pair")
  }
  match RelocTypeGeneric::from_int(2) {
    Some(Sectdiff) => ()
    _ => fail("Expected Sectdiff")
  }
  match RelocTypeGeneric::from_int(3) {
    Some(PbLaPtr) => ()
    _ => fail("Expected PbLaPtr")
  }
  match RelocTypeGeneric::from_int(4) {
    Some(LocalSectdiff) => ()
    _ => fail("Expected LocalSectdiff")
  }
  match RelocTypeGeneric::from_int(5) {
    Some(Tlv) => ()
    _ => fail("Expected Tlv")
  }
}

///|
test "RelocTypeGeneric from_int invalid" {
  match RelocTypeGeneric::from_int(6) {
    None => ()
    _ => fail("Expected None for invalid value")
  }
  match RelocTypeGeneric::from_int(-1) {
    None => ()
    _ => fail("Expected None for negative value")
  }
}

///|
test "RelocTypeX86_64 to_int" {
  assert_eq(RelocTypeX86_64::Unsigned.to_int(), 0)
  assert_eq(RelocTypeX86_64::Signed.to_int(), 1)
  assert_eq(RelocTypeX86_64::Branch.to_int(), 2)
  assert_eq(RelocTypeX86_64::GotLoad.to_int(), 3)
  assert_eq(RelocTypeX86_64::Got.to_int(), 4)
  assert_eq(RelocTypeX86_64::Subtractor.to_int(), 5)
  assert_eq(RelocTypeX86_64::Signed1.to_int(), 6)
  assert_eq(RelocTypeX86_64::Signed2.to_int(), 7)
  assert_eq(RelocTypeX86_64::Signed4.to_int(), 8)
  assert_eq(RelocTypeX86_64::Tlv.to_int(), 9)
}

///|
test "RelocTypeX86_64 from_int valid" {
  match RelocTypeX86_64::from_int(0) {
    Some(Unsigned) => ()
    _ => fail("Expected Unsigned")
  }
  match RelocTypeX86_64::from_int(5) {
    Some(Subtractor) => ()
    _ => fail("Expected Subtractor")
  }
  match RelocTypeX86_64::from_int(9) {
    Some(Tlv) => ()
    _ => fail("Expected Tlv")
  }
}

///|
test "RelocTypeX86_64 from_int invalid" {
  match RelocTypeX86_64::from_int(10) {
    None => ()
    _ => fail("Expected None for invalid value")
  }
}

///|
test "RelocTypeARM to_int" {
  assert_eq(RelocTypeARM::Vanilla.to_int(), 0)
  assert_eq(RelocTypeARM::Pair.to_int(), 1)
  assert_eq(RelocTypeARM::Sectdiff.to_int(), 2)
  assert_eq(RelocTypeARM::LocalSectdiff.to_int(), 3)
  assert_eq(RelocTypeARM::PbLaPtr.to_int(), 4)
  assert_eq(RelocTypeARM::Br24.to_int(), 5)
  assert_eq(RelocTypeARM::ThumbBr22.to_int(), 6)
  assert_eq(RelocTypeARM::Thumb32BitBranch.to_int(), 7)
  assert_eq(RelocTypeARM::Half.to_int(), 8)
  assert_eq(RelocTypeARM::HalfSectdiff.to_int(), 9)
}

///|
test "RelocTypeARM from_int valid" {
  match RelocTypeARM::from_int(0) {
    Some(Vanilla) => ()
    _ => fail("Expected Vanilla")
  }
  match RelocTypeARM::from_int(6) {
    Some(ThumbBr22) => ()
    _ => fail("Expected ThumbBr22")
  }
}

///|
test "RelocTypeARM from_int invalid" {
  match RelocTypeARM::from_int(10) {
    None => ()
    _ => fail("Expected None for invalid value")
  }
}

///|
test "RelocTypeARM64 to_int" {
  assert_eq(RelocTypeARM64::Unsigned.to_int(), 0)
  assert_eq(RelocTypeARM64::Subtractor.to_int(), 1)
  assert_eq(RelocTypeARM64::Branch26.to_int(), 2)
  assert_eq(RelocTypeARM64::Page21.to_int(), 3)
  assert_eq(RelocTypeARM64::Pageoff12.to_int(), 4)
  assert_eq(RelocTypeARM64::GotLoadPage21.to_int(), 5)
  assert_eq(RelocTypeARM64::GotLoadPageoff12.to_int(), 6)
  assert_eq(RelocTypeARM64::PointerToGot.to_int(), 7)
  assert_eq(RelocTypeARM64::TlvpLoadPage21.to_int(), 8)
  assert_eq(RelocTypeARM64::TlvpLoadPageoff12.to_int(), 9)
  assert_eq(RelocTypeARM64::Addend.to_int(), 10)
}

///|
test "RelocTypeARM64 from_int valid" {
  match RelocTypeARM64::from_int(0) {
    Some(Unsigned) => ()
    _ => fail("Expected Unsigned")
  }
  match RelocTypeARM64::from_int(10) {
    Some(Addend) => ()
    _ => fail("Expected Addend")
  }
}

///|
test "RelocTypeARM64 from_int invalid" {
  match RelocTypeARM64::from_int(11) {
    None => ()
    _ => fail("Expected None for invalid value")
  }
}
