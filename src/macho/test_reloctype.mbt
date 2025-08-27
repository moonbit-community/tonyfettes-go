///|
test "RelocTypeGeneric to_int" {
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_VANILLA.to_int(), 0)
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_PAIR.to_int(), 1)
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_SECTDIFF.to_int(), 2)
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_PB_LA_PTR.to_int(), 3)
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_LOCAL_SECTDIFF.to_int(), 4)
  assert_eq(RelocTypeGeneric::GENERIC_RELOC_TLV.to_int(), 5)
}

///|
test "RelocTypeGeneric from_int valid" {
  match RelocTypeGeneric::from_int(0) {
    Some(GENERIC_RELOC_VANILLA) => ()
    _ => fail("Expected GENERIC_RELOC_VANILLA")
  }
  match RelocTypeGeneric::from_int(1) {
    Some(GENERIC_RELOC_PAIR) => ()
    _ => fail("Expected GENERIC_RELOC_PAIR")
  }
  match RelocTypeGeneric::from_int(2) {
    Some(GENERIC_RELOC_SECTDIFF) => ()
    _ => fail("Expected GENERIC_RELOC_SECTDIFF")
  }
  match RelocTypeGeneric::from_int(3) {
    Some(GENERIC_RELOC_PB_LA_PTR) => ()
    _ => fail("Expected GENERIC_RELOC_PB_LA_PTR")
  }
  match RelocTypeGeneric::from_int(4) {
    Some(GENERIC_RELOC_LOCAL_SECTDIFF) => ()
    _ => fail("Expected GENERIC_RELOC_LOCAL_SECTDIFF")
  }
  match RelocTypeGeneric::from_int(5) {
    Some(GENERIC_RELOC_TLV) => ()
    _ => fail("Expected GENERIC_RELOC_TLV")
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
  assert_eq(RelocTypeX86_64::X86_64_RELOC_UNSIGNED.to_int(), 0)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_SIGNED.to_int(), 1)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_BRANCH.to_int(), 2)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_GOT_LOAD.to_int(), 3)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_GOT.to_int(), 4)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_SUBTRACTOR.to_int(), 5)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_SIGNED_1.to_int(), 6)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_SIGNED_2.to_int(), 7)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_SIGNED_4.to_int(), 8)
  assert_eq(RelocTypeX86_64::X86_64_RELOC_TLV.to_int(), 9)
}

///|
test "RelocTypeX86_64 from_int valid" {
  match RelocTypeX86_64::from_int(0) {
    Some(X86_64_RELOC_UNSIGNED) => ()
    _ => fail("Expected X86_64_RELOC_UNSIGNED")
  }
  match RelocTypeX86_64::from_int(5) {
    Some(X86_64_RELOC_SUBTRACTOR) => ()
    _ => fail("Expected X86_64_RELOC_SUBTRACTOR")
  }
  match RelocTypeX86_64::from_int(9) {
    Some(X86_64_RELOC_TLV) => ()
    _ => fail("Expected X86_64_RELOC_TLV")
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
  assert_eq(RelocTypeARM::ARM_RELOC_VANILLA.to_int(), 0)
  assert_eq(RelocTypeARM::ARM_RELOC_PAIR.to_int(), 1)
  assert_eq(RelocTypeARM::ARM_RELOC_SECTDIFF.to_int(), 2)
  assert_eq(RelocTypeARM::ARM_RELOC_LOCAL_SECTDIFF.to_int(), 3)
  assert_eq(RelocTypeARM::ARM_RELOC_PB_LA_PTR.to_int(), 4)
  assert_eq(RelocTypeARM::ARM_RELOC_BR24.to_int(), 5)
  assert_eq(RelocTypeARM::ARM_THUMB_RELOC_BR22.to_int(), 6)
  assert_eq(RelocTypeARM::ARM_THUMB_32BIT_BRANCH.to_int(), 7)
  assert_eq(RelocTypeARM::ARM_RELOC_HALF.to_int(), 8)
  assert_eq(RelocTypeARM::ARM_RELOC_HALF_SECTDIFF.to_int(), 9)
}

///|
test "RelocTypeARM from_int valid" {
  match RelocTypeARM::from_int(0) {
    Some(ARM_RELOC_VANILLA) => ()
    _ => fail("Expected ARM_RELOC_VANILLA")
  }
  match RelocTypeARM::from_int(6) {
    Some(ARM_THUMB_RELOC_BR22) => ()
    _ => fail("Expected ARM_THUMB_RELOC_BR22")
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
  assert_eq(RelocTypeARM64::ARM64_RELOC_UNSIGNED.to_int(), 0)
  assert_eq(RelocTypeARM64::ARM64_RELOC_SUBTRACTOR.to_int(), 1)
  assert_eq(RelocTypeARM64::ARM64_RELOC_BRANCH26.to_int(), 2)
  assert_eq(RelocTypeARM64::ARM64_RELOC_PAGE21.to_int(), 3)
  assert_eq(RelocTypeARM64::ARM64_RELOC_PAGEOFF12.to_int(), 4)
  assert_eq(RelocTypeARM64::ARM64_RELOC_GOT_LOAD_PAGE21.to_int(), 5)
  assert_eq(RelocTypeARM64::ARM64_RELOC_GOT_LOAD_PAGEOFF12.to_int(), 6)
  assert_eq(RelocTypeARM64::ARM64_RELOC_POINTER_TO_GOT.to_int(), 7)
  assert_eq(RelocTypeARM64::ARM64_RELOC_TLVP_LOAD_PAGE21.to_int(), 8)
  assert_eq(RelocTypeARM64::ARM64_RELOC_TLVP_LOAD_PAGEOFF12.to_int(), 9)
  assert_eq(RelocTypeARM64::ARM64_RELOC_ADDEND.to_int(), 10)
}

///|
test "RelocTypeARM64 from_int valid" {
  match RelocTypeARM64::from_int(0) {
    Some(ARM64_RELOC_UNSIGNED) => ()
    _ => fail("Expected ARM64_RELOC_UNSIGNED")
  }
  match RelocTypeARM64::from_int(10) {
    Some(ARM64_RELOC_ADDEND) => ()
    _ => fail("Expected ARM64_RELOC_ADDEND")
  }
}

///|
test "RelocTypeARM64 from_int invalid" {
  match RelocTypeARM64::from_int(11) {
    None => ()
    _ => fail("Expected None for invalid value")
  }
}
