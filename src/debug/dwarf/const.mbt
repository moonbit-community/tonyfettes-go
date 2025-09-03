/// Constants and enumerations for DWARF debug information format
/// Ported from Go's debug/dwarf package

///|
/// An Attr identifies the attribute type in a DWARF Entry.Field.
pub enum Attr {
  // DWARF 2
  AttrSibling
  AttrLocation
  AttrName
  AttrOrdering
  AttrByteSize
  AttrBitOffset
  AttrBitSize
  AttrStmtList
  AttrLowpc
  AttrHighpc
  AttrLanguage
  AttrDiscr
  AttrDiscrValue
  AttrVisibility
  AttrImport
  AttrStringLength
  AttrCommonRef
  AttrCompDir
  AttrConstValue
  AttrContainingType
  AttrDefaultValue
  AttrInline
  AttrIsOptional
  AttrLowerBound
  AttrProducer
  AttrPrototyped
  AttrReturnAddr
  AttrStartScope
  AttrStrideSize
  AttrUpperBound
  AttrAbstractOrigin
  AttrAccessibility
  AttrAddrClass
  AttrArtificial
  AttrBaseTypes
  AttrCalling
  AttrCount
  AttrDataMemberLoc
  AttrDeclColumn
  AttrDeclFile
  AttrDeclLine
  AttrDeclaration
  AttrDiscrList
  AttrEncoding
  AttrExternal
  AttrFrameBase
  AttrFriend
  AttrIdentifierCase
  AttrMacroInfo
  AttrNamelistItem
  AttrPriority
  AttrSegment
  AttrSpecification
  AttrStaticLink
  AttrType
  AttrUseLocation
  AttrVarParam
  AttrVirtuality
  AttrVtableElemLoc
  // DWARF 3
  AttrAllocated
  AttrAssociated
  AttrDataLocation
  AttrStride
  AttrEntrypc
  AttrUseUTF8
  AttrExtension
  AttrRanges
  AttrTrampoline
  AttrCallColumn
  AttrCallFile
  AttrCallLine
  AttrDescription
  AttrBinaryScale
  AttrDecimalScale
  AttrSmall
  AttrDecimalSign
  AttrDigitCount
  AttrPictureString
  AttrMutable
  AttrThreadsScaled
  AttrExplicit
  AttrObjectPointer
  AttrEndianity
  AttrElemental
  AttrPure
  AttrRecursive
  // DWARF 4
  AttrSignature
  AttrMainSubprogram
  AttrDataBitOffset
  AttrConstExpr
  AttrEnumClass
  AttrLinkageName
  // DWARF 5
  AttrStringLengthBitSize
  AttrStringLengthByteSize
  AttrRank
  AttrStrOffsetsBase
  AttrAddrBase
  AttrRnglistsBase
  AttrDwoName
  AttrReference
  AttrRvalueReference
  AttrMacros
  AttrCallAllCalls
  AttrCallAllSourceCalls
  AttrCallAllTailCalls
  AttrCallReturnPC
  AttrCallValue
  AttrCallOrigin
  AttrCallParameter
  AttrCallPC
  AttrCallTailCall
  AttrCallTarget
  AttrCallTargetClobbered
  AttrCallDataLocation
  AttrCallDataValue
  AttrNoreturn
  AttrAlignment
  AttrExportSymbols
  AttrDeleted
  AttrDefaulted
  AttrLoclistsBase
} derive(Show, Eq)

///|
/// Convert Attr to its corresponding UInt value
pub fn Attr::to_uint(self : Attr) -> UInt {
  match self {
    AttrSibling => 0x01U
    AttrLocation => 0x02U
    AttrName => 0x03U
    AttrOrdering => 0x09U
    AttrByteSize => 0x0BU
    AttrBitOffset => 0x0CU
    AttrBitSize => 0x0DU
    AttrStmtList => 0x10U
    AttrLowpc => 0x11U
    AttrHighpc => 0x12U
    AttrLanguage => 0x13U
    AttrDiscr => 0x15U
    AttrDiscrValue => 0x16U
    AttrVisibility => 0x17U
    AttrImport => 0x18U
    AttrStringLength => 0x19U
    AttrCommonRef => 0x1AU
    AttrCompDir => 0x1BU
    AttrConstValue => 0x1CU
    AttrContainingType => 0x1DU
    AttrDefaultValue => 0x1EU
    AttrInline => 0x20U
    AttrIsOptional => 0x21U
    AttrLowerBound => 0x22U
    AttrProducer => 0x25U
    AttrPrototyped => 0x27U
    AttrReturnAddr => 0x2AU
    AttrStartScope => 0x2CU
    AttrStrideSize => 0x2EU
    AttrUpperBound => 0x2FU
    AttrAbstractOrigin => 0x31U
    AttrAccessibility => 0x32U
    AttrAddrClass => 0x33U
    AttrArtificial => 0x34U
    AttrBaseTypes => 0x35U
    AttrCalling => 0x36U
    AttrCount => 0x37U
    AttrDataMemberLoc => 0x38U
    AttrDeclColumn => 0x39U
    AttrDeclFile => 0x3AU
    AttrDeclLine => 0x3BU
    AttrDeclaration => 0x3CU
    AttrDiscrList => 0x3DU
    AttrEncoding => 0x3EU
    AttrExternal => 0x3FU
    AttrFrameBase => 0x40U
    AttrFriend => 0x41U
    AttrIdentifierCase => 0x42U
    AttrMacroInfo => 0x43U
    AttrNamelistItem => 0x44U
    AttrPriority => 0x45U
    AttrSegment => 0x46U
    AttrSpecification => 0x47U
    AttrStaticLink => 0x48U
    AttrType => 0x49U
    AttrUseLocation => 0x4AU
    AttrVarParam => 0x4BU
    AttrVirtuality => 0x4CU
    AttrVtableElemLoc => 0x4DU
    AttrAllocated => 0x4EU
    AttrAssociated => 0x4FU
    AttrDataLocation => 0x50U
    AttrStride => 0x51U
    AttrEntrypc => 0x52U
    AttrUseUTF8 => 0x53U
    AttrExtension => 0x54U
    AttrRanges => 0x55U
    AttrTrampoline => 0x56U
    AttrCallColumn => 0x57U
    AttrCallFile => 0x58U
    AttrCallLine => 0x59U
    AttrDescription => 0x5AU
    AttrBinaryScale => 0x5BU
    AttrDecimalScale => 0x5CU
    AttrSmall => 0x5DU
    AttrDecimalSign => 0x5EU
    AttrDigitCount => 0x5FU
    AttrPictureString => 0x60U
    AttrMutable => 0x61U
    AttrThreadsScaled => 0x62U
    AttrExplicit => 0x63U
    AttrObjectPointer => 0x64U
    AttrEndianity => 0x65U
    AttrElemental => 0x66U
    AttrPure => 0x67U
    AttrRecursive => 0x68U
    AttrSignature => 0x69U
    AttrMainSubprogram => 0x6AU
    AttrDataBitOffset => 0x6BU
    AttrConstExpr => 0x6CU
    AttrEnumClass => 0x6DU
    AttrLinkageName => 0x6EU
    AttrStringLengthBitSize => 0x6FU
    AttrStringLengthByteSize => 0x70U
    AttrRank => 0x71U
    AttrStrOffsetsBase => 0x72U
    AttrAddrBase => 0x73U
    AttrRnglistsBase => 0x74U
    AttrDwoName => 0x76U
    AttrReference => 0x77U
    AttrRvalueReference => 0x78U
    AttrMacros => 0x79U
    AttrCallAllCalls => 0x7AU
    AttrCallAllSourceCalls => 0x7BU
    AttrCallAllTailCalls => 0x7CU
    AttrCallReturnPC => 0x7DU
    AttrCallValue => 0x7EU
    AttrCallOrigin => 0x7FU
    AttrCallParameter => 0x80U
    AttrCallPC => 0x81U
    AttrCallTailCall => 0x82U
    AttrCallTarget => 0x83U
    AttrCallTargetClobbered => 0x84U
    AttrCallDataLocation => 0x85U
    AttrCallDataValue => 0x86U
    AttrNoreturn => 0x87U
    AttrAlignment => 0x88U
    AttrExportSymbols => 0x89U
    AttrDeleted => 0x8AU
    AttrDefaulted => 0x8BU
    AttrLoclistsBase => 0x8CU
  }
}

///|
/// Convert UInt to Format  
fn Format::from_uint(val : UInt) -> Format? {
  match val {
    0x01U => Some(FormAddr)
    0x03U => Some(FormDwarfBlock2)
    0x04U => Some(FormDwarfBlock4)
    0x05U => Some(FormData2)
    0x06U => Some(FormData4)
    0x07U => Some(FormData8)
    0x08U => Some(FormString)
    0x09U => Some(FormDwarfBlock)
    0x0AU => Some(FormDwarfBlock1)
    0x0BU => Some(FormData1)
    0x0CU => Some(FormFlag)
    0x0DU => Some(FormSdata)
    0x0EU => Some(FormStrp)
    0x0FU => Some(FormUdata)
    0x10U => Some(FormRefAddr)
    0x11U => Some(FormRef1)
    0x12U => Some(FormRef2)
    0x13U => Some(FormRef4)
    0x14U => Some(FormRef8)
    0x15U => Some(FormRefUdata)
    0x16U => Some(FormIndirect)
    0x17U => Some(FormSecOffset)
    0x18U => Some(FormExprloc)
    0x19U => Some(FormFlagPresent)
    0x20U => Some(FormRefSig8)
    0x1AU => Some(FormStrx)
    0x1BU => Some(FormAddrx)
    0x1CU => Some(FormRefSup4)
    0x1DU => Some(FormStrpSup)
    0x1EU => Some(FormData16)
    0x1FU => Some(FormLineStrp)
    0x21U => Some(FormImplicitConst)
    0x22U => Some(FormLoclistx)
    0x23U => Some(FormRnglistx)
    0x24U => Some(FormRefSup8)
    0x25U => Some(FormStrx1)
    0x26U => Some(FormStrx2)
    0x27U => Some(FormStrx3)
    0x28U => Some(FormStrx4)
    0x29U => Some(FormAddrx1)
    0x2AU => Some(FormAddrx2)
    0x2BU => Some(FormAddrx3)
    0x2CU => Some(FormAddrx4)
    0x1F20U => Some(FormGnuRefAlt)
    0x1F21U => Some(FormGnuStrpAlt)
    _ => None
  }
}

///|
/// Convert UInt to Tag
pub fn Tag::from_uint(val : UInt) -> Tag? {
  match val {
    0x01U => Some(TagArrayType)
    0x02U => Some(TagClassType)
    0x03U => Some(TagEntryPoint)
    0x04U => Some(TagEnumerationType)
    0x05U => Some(TagFormalParameter)
    0x08U => Some(TagImportedDeclaration)
    0x0AU => Some(TagLabel)
    0x0BU => Some(TagLexDwarfBlock)
    0x0DU => Some(TagMember)
    0x0FU => Some(TagPointerType)
    0x10U => Some(TagReferenceType)
    0x11U => Some(TagCompileUnit)
    0x12U => Some(TagStringType)
    0x13U => Some(TagStructType)
    0x15U => Some(TagSubroutineType)
    0x16U => Some(TagTypedef)
    0x17U => Some(TagUnionType)
    0x18U => Some(TagUnspecifiedParameters)
    0x19U => Some(TagVariant)
    0x1AU => Some(TagCommonDwarfBlock)
    0x1BU => Some(TagCommonInclusion)
    0x1CU => Some(TagInheritance)
    0x1DU => Some(TagInlinedSubroutine)
    0x1EU => Some(TagModule)
    0x1FU => Some(TagPtrToMemberType)
    0x20U => Some(TagSetType)
    0x21U => Some(TagSubrangeType)
    0x22U => Some(TagWithStmt)
    0x23U => Some(TagAccessDeclaration)
    0x24U => Some(TagBaseType)
    0x25U => Some(TagCatchDwarfBlock)
    0x26U => Some(TagConstType)
    0x27U => Some(TagConstant)
    0x28U => Some(TagEnumerator)
    0x29U => Some(TagFileType)
    0x2AU => Some(TagFriend)
    0x2BU => Some(TagNamelist)
    0x2CU => Some(TagNamelistItem)
    0x2DU => Some(TagPackedType)
    0x2EU => Some(TagSubprogram)
    0x2FU => Some(TagTemplateTypeParameter)
    0x30U => Some(TagTemplateValueParameter)
    0x31U => Some(TagThrownType)
    0x32U => Some(TagTryDwarfBlock)
    0x33U => Some(TagVariantPart)
    0x34U => Some(TagVariable)
    0x35U => Some(TagVolatileType)
    0x36U => Some(TagDwarfProcedure)
    0x37U => Some(TagRestrictType)
    0x38U => Some(TagInterfaceType)
    0x39U => Some(TagNamespace)
    0x3AU => Some(TagImportedModule)
    0x3BU => Some(TagUnspecifiedType)
    0x3CU => Some(TagPartialUnit)
    0x3DU => Some(TagImportedUnit)
    0x3EU => Some(TagMutableType)
    0x3FU => Some(TagCondition)
    0x40U => Some(TagSharedType)
    0x41U => Some(TagTypeUnit)
    0x42U => Some(TagRvalueReferenceType)
    0x43U => Some(TagTemplateAlias)
    0x44U => Some(TagCoarrayType)
    0x45U => Some(TagGenericSubrange)
    0x46U => Some(TagDynamicType)
    0x47U => Some(TagAtomicType)
    0x48U => Some(TagCallSite)
    0x49U => Some(TagCallSiteParameter)
    0x4AU => Some(TagSkeletonUnit)
    0x4BU => Some(TagImmutableType)
    _ => None
  }
}

///|
/// Convert UInt to Attr
pub fn Attr::from_uint(val : UInt) -> Attr? {
  match val {
    0x01U => Some(AttrSibling)
    0x02U => Some(AttrLocation)
    0x03U => Some(AttrName)
    0x09U => Some(AttrOrdering)
    0x0BU => Some(AttrByteSize)
    0x0CU => Some(AttrBitOffset)
    0x0DU => Some(AttrBitSize)
    0x10U => Some(AttrStmtList)
    0x11U => Some(AttrLowpc)
    0x12U => Some(AttrHighpc)
    0x13U => Some(AttrLanguage)
    0x15U => Some(AttrDiscr)
    0x16U => Some(AttrDiscrValue)
    0x17U => Some(AttrVisibility)
    0x18U => Some(AttrImport)
    0x19U => Some(AttrStringLength)
    0x1AU => Some(AttrCommonRef)
    0x1BU => Some(AttrCompDir)
    0x1CU => Some(AttrConstValue)
    0x1DU => Some(AttrContainingType)
    0x1EU => Some(AttrDefaultValue)
    0x20U => Some(AttrInline)
    0x21U => Some(AttrIsOptional)
    0x22U => Some(AttrLowerBound)
    0x25U => Some(AttrProducer)
    0x27U => Some(AttrPrototyped)
    0x2AU => Some(AttrReturnAddr)
    0x2CU => Some(AttrStartScope)
    0x2EU => Some(AttrStrideSize)
    0x2FU => Some(AttrUpperBound)
    0x31U => Some(AttrAbstractOrigin)
    0x32U => Some(AttrAccessibility)
    0x33U => Some(AttrAddrClass)
    0x34U => Some(AttrArtificial)
    0x35U => Some(AttrBaseTypes)
    0x36U => Some(AttrCalling)
    0x37U => Some(AttrCount)
    0x38U => Some(AttrDataMemberLoc)
    0x39U => Some(AttrDeclColumn)
    0x3AU => Some(AttrDeclFile)
    0x3BU => Some(AttrDeclLine)
    0x3CU => Some(AttrDeclaration)
    0x3DU => Some(AttrDiscrList)
    0x3EU => Some(AttrEncoding)
    0x3FU => Some(AttrExternal)
    0x40U => Some(AttrFrameBase)
    0x41U => Some(AttrFriend)
    0x42U => Some(AttrIdentifierCase)
    0x43U => Some(AttrMacroInfo)
    0x44U => Some(AttrNamelistItem)
    0x45U => Some(AttrPriority)
    0x46U => Some(AttrSegment)
    0x47U => Some(AttrSpecification)
    0x48U => Some(AttrStaticLink)
    0x49U => Some(AttrType)
    0x4AU => Some(AttrUseLocation)
    0x4BU => Some(AttrVarParam)
    0x4CU => Some(AttrVirtuality)
    0x4DU => Some(AttrVtableElemLoc)
    0x4EU => Some(AttrAllocated)
    0x4FU => Some(AttrAssociated)
    0x50U => Some(AttrDataLocation)
    0x51U => Some(AttrStride)
    0x52U => Some(AttrEntrypc)
    0x53U => Some(AttrUseUTF8)
    0x54U => Some(AttrExtension)
    0x55U => Some(AttrRanges)
    0x56U => Some(AttrTrampoline)
    0x57U => Some(AttrCallColumn)
    0x58U => Some(AttrCallFile)
    0x59U => Some(AttrCallLine)
    0x5AU => Some(AttrDescription)
    0x5BU => Some(AttrBinaryScale)
    0x5CU => Some(AttrDecimalScale)
    0x5DU => Some(AttrSmall)
    0x5EU => Some(AttrDecimalSign)
    0x5FU => Some(AttrDigitCount)
    0x60U => Some(AttrPictureString)
    0x61U => Some(AttrMutable)
    0x62U => Some(AttrThreadsScaled)
    0x63U => Some(AttrExplicit)
    0x64U => Some(AttrObjectPointer)
    0x65U => Some(AttrEndianity)
    0x66U => Some(AttrElemental)
    0x67U => Some(AttrPure)
    0x68U => Some(AttrRecursive)
    0x69U => Some(AttrSignature)
    0x6AU => Some(AttrMainSubprogram)
    0x6BU => Some(AttrDataBitOffset)
    0x6CU => Some(AttrConstExpr)
    0x6DU => Some(AttrEnumClass)
    0x6EU => Some(AttrLinkageName)
    0x6FU => Some(AttrStringLengthBitSize)
    0x70U => Some(AttrStringLengthByteSize)
    0x71U => Some(AttrRank)
    0x72U => Some(AttrStrOffsetsBase)
    0x73U => Some(AttrAddrBase)
    0x74U => Some(AttrRnglistsBase)
    0x76U => Some(AttrDwoName)
    0x77U => Some(AttrReference)
    0x78U => Some(AttrRvalueReference)
    0x79U => Some(AttrMacros)
    0x7AU => Some(AttrCallAllCalls)
    0x7BU => Some(AttrCallAllSourceCalls)
    0x7CU => Some(AttrCallAllTailCalls)
    0x7DU => Some(AttrCallReturnPC)
    0x7EU => Some(AttrCallValue)
    0x7FU => Some(AttrCallOrigin)
    0x80U => Some(AttrCallParameter)
    0x81U => Some(AttrCallPC)
    0x82U => Some(AttrCallTailCall)
    0x83U => Some(AttrCallTarget)
    0x84U => Some(AttrCallTargetClobbered)
    0x85U => Some(AttrCallDataLocation)
    0x86U => Some(AttrCallDataValue)
    0x87U => Some(AttrNoreturn)
    0x88U => Some(AttrAlignment)
    0x89U => Some(AttrExportSymbols)
    0x8AU => Some(AttrDeleted)
    0x8BU => Some(AttrDefaulted)
    0x8CU => Some(AttrLoclistsBase)
    _ => None
  }
}

///|
/// A format is a DWARF data encoding format.
pub enum Format {
  // Value formats
  FormAddr
  FormDwarfBlock2
  FormDwarfBlock4
  FormData2
  FormData4
  FormData8
  FormString
  FormDwarfBlock
  FormDwarfBlock1
  FormData1
  FormFlag
  FormSdata
  FormStrp
  FormUdata
  FormRefAddr
  FormRef1
  FormRef2
  FormRef4
  FormRef8
  FormRefUdata
  FormIndirect
  // DWARF 4
  FormSecOffset
  FormExprloc
  FormFlagPresent
  FormRefSig8
  // DWARF 5
  FormStrx
  FormAddrx
  FormRefSup4
  FormStrpSup
  FormData16
  FormLineStrp
  FormImplicitConst
  FormLoclistx
  FormRnglistx
  FormRefSup8
  FormStrx1
  FormStrx2
  FormStrx3
  FormStrx4
  FormAddrx1
  FormAddrx2
  FormAddrx3
  FormAddrx4
  // Extensions for multi-file compression (.dwz)
  FormGnuRefAlt
  FormGnuStrpAlt
} derive(Show, Eq)

///|
/// A Tag is the classification (the type) of an Entry.
pub enum Tag {
  TagArrayType
  TagClassType
  TagEntryPoint
  TagEnumerationType
  TagFormalParameter
  TagImportedDeclaration
  TagLabel
  TagLexDwarfBlock
  TagMember
  TagPointerType
  TagReferenceType
  TagCompileUnit
  TagStringType
  TagStructType
  TagSubroutineType
  TagTypedef
  TagUnionType
  TagUnspecifiedParameters
  TagVariant
  TagCommonDwarfBlock
  TagCommonInclusion
  TagInheritance
  TagInlinedSubroutine
  TagModule
  TagPtrToMemberType
  TagSetType
  TagSubrangeType
  TagWithStmt
  TagAccessDeclaration
  TagBaseType
  TagCatchDwarfBlock
  TagConstType
  TagConstant
  TagEnumerator
  TagFileType
  TagFriend
  TagNamelist
  TagNamelistItem
  TagPackedType
  TagSubprogram
  TagTemplateTypeParameter
  TagTemplateValueParameter
  TagThrownType
  TagTryDwarfBlock
  TagVariantPart
  TagVariable
  TagVolatileType
  // DWARF 3
  TagDwarfProcedure
  TagRestrictType
  TagInterfaceType
  TagNamespace
  TagImportedModule
  TagUnspecifiedType
  TagPartialUnit
  TagImportedUnit
  TagMutableType
  TagCondition
  TagSharedType
  // DWARF 4
  TagTypeUnit
  TagRvalueReferenceType
  TagTemplateAlias
  // DWARF 5
  TagCoarrayType
  TagGenericSubrange
  TagDynamicType
  TagAtomicType
  TagCallSite
  TagCallSiteParameter
  TagSkeletonUnit
  TagImmutableType
  Tag(UInt)
} derive(Show, Eq)

///|
/// Convert Tag to its corresponding UInt value
pub fn Tag::to_uint(self : Tag) -> UInt {
  match self {
    TagArrayType => 0x01
    TagClassType => 0x02
    TagEntryPoint => 0x03
    TagEnumerationType => 0x04
    TagFormalParameter => 0x05
    TagImportedDeclaration => 0x08
    TagLabel => 0x0A
    TagLexDwarfBlock => 0x0B
    TagMember => 0x0D
    TagPointerType => 0x0F
    TagReferenceType => 0x10
    TagCompileUnit => 0x11
    TagStringType => 0x12
    TagStructType => 0x13
    TagSubroutineType => 0x15
    TagTypedef => 0x16
    TagUnionType => 0x17
    TagUnspecifiedParameters => 0x18
    TagVariant => 0x19
    TagCommonDwarfBlock => 0x1A
    TagCommonInclusion => 0x1B
    TagInheritance => 0x1C
    TagInlinedSubroutine => 0x1D
    TagModule => 0x1E
    TagPtrToMemberType => 0x1F
    TagSetType => 0x20
    TagSubrangeType => 0x21
    TagWithStmt => 0x22
    TagAccessDeclaration => 0x23
    TagBaseType => 0x24
    TagCatchDwarfBlock => 0x25
    TagConstType => 0x26
    TagConstant => 0x27
    TagEnumerator => 0x28
    TagFileType => 0x29
    TagFriend => 0x2A
    TagNamelist => 0x2B
    TagNamelistItem => 0x2C
    TagPackedType => 0x2D
    TagSubprogram => 0x2E
    TagTemplateTypeParameter => 0x2F
    TagTemplateValueParameter => 0x30
    TagThrownType => 0x31
    TagTryDwarfBlock => 0x32
    TagVariantPart => 0x33
    TagVariable => 0x34
    TagVolatileType => 0x35
    TagDwarfProcedure => 0x36
    TagRestrictType => 0x37
    TagInterfaceType => 0x38
    TagNamespace => 0x39
    TagImportedModule => 0x3A
    TagUnspecifiedType => 0x3B
    TagPartialUnit => 0x3C
    TagImportedUnit => 0x3D
    TagMutableType => 0x3E
    TagCondition => 0x3F
    TagSharedType => 0x40
    TagTypeUnit => 0x41
    TagRvalueReferenceType => 0x42
    TagTemplateAlias => 0x43
    TagCoarrayType => 0x44
    TagGenericSubrange => 0x45
    TagDynamicType => 0x46
    TagAtomicType => 0x47
    TagCallSite => 0x48
    TagCallSiteParameter => 0x49
    TagSkeletonUnit => 0x4A
    TagImmutableType => 0x4B
    Tag(tag) => tag
  }
}

///|
/// Location expression operators
/// The debug info encodes value locations like 8(R3) as a sequence of these op codes.
const OpAddr : UInt = 0x03U

///|
const OpDeref : UInt = 0x06U

///|
const OpConst1u : UInt = 0x08U

///|
const OpConst1s : UInt = 0x09U

///|
const OpConst2u : UInt = 0x0AU

///|
const OpConst2s : UInt = 0x0BU

///|
const OpConst4u : UInt = 0x0CU

///|
const OpConst4s : UInt = 0x0DU

///|
const OpConst8u : UInt = 0x0EU

///|
const OpConst8s : UInt = 0x0FU

///|
const OpConstu : UInt = 0x10U

///|
const OpConsts : UInt = 0x11U

///|
const OpDup : UInt = 0x12U

///|
const OpDrop : UInt = 0x13U

///|
const OpOver : UInt = 0x14U

///|
const OpPick : UInt = 0x15U

///|
const OpSwap : UInt = 0x16U

///|
const OpRot : UInt = 0x17U

///|
const OpXderef : UInt = 0x18U

///|
const OpAbs : UInt = 0x19U

///|
const OpAnd : UInt = 0x1AU

///|
const OpDiv : UInt = 0x1BU

///|
const OpMinus : UInt = 0x1CU

///|
const OpMod : UInt = 0x1DU

///|
const OpMul : UInt = 0x1EU

///|
const OpNeg : UInt = 0x1FU

///|
const OpNot : UInt = 0x20U

///|
const OpOr : UInt = 0x21U

///|
const OpPlus : UInt = 0x22U

///|
const OpPlusUconst : UInt = 0x23U

///|
const OpShl : UInt = 0x24U

///|
const OpShr : UInt = 0x25U

///|
const OpShra : UInt = 0x26U

///|
const OpXor : UInt = 0x27U

///|
const OpSkip : UInt = 0x2FU

///|
const OpBra : UInt = 0x28U

///|
const OpEq : UInt = 0x29U

///|
const OpGe : UInt = 0x2AU

///|
const OpGt : UInt = 0x2BU

///|
const OpLe : UInt = 0x2CU

///|
const OpLt : UInt = 0x2DU

///|
const OpNe : UInt = 0x2EU

///|
const OpLit0 : UInt = 0x30U

///|
const OpReg0 : UInt = 0x50U

///|
const OpBreg0 : UInt = 0x70U

///|
const OpRegx : UInt = 0x90U

///|
const OpFbreg : UInt = 0x91U

///|
const OpBregx : UInt = 0x92U

///|
const OpPiece : UInt = 0x93U

///|
const OpDerefSize : UInt = 0x94U

///|
const OpXderefSize : UInt = 0x95U

///|
const OpNop : UInt = 0x96U
/// DWARF 3

///|
const OpPushObjAddr : UInt = 0x97U

///|
const OpCall2 : UInt = 0x98U

///|
const OpCall4 : UInt = 0x99U

///|
const OpCallRef : UInt = 0x9AU

///|
const OpFormTlsAddress : UInt = 0x9BU

///|
const OpCallFrameCfa : UInt = 0x9CU

///|
const OpBitPiece : UInt = 0x9DU
/// DWARF 4

///|
const OpImplicitValue : UInt = 0x9EU

///|
const OpStackValue : UInt = 0x9FU
/// DWARF 5

///|
const OpImplicitPointer : UInt = 0xA0U

///|
const OpAddrx : UInt = 0xA1U

///|
const OpConstx : UInt = 0xA2U

///|
const OpEntryValue : UInt = 0xA3U

///|
const OpConstType : UInt = 0xA4U

///|
const OpRegvalType : UInt = 0xA5U

///|
const OpDerefType : UInt = 0xA6U

///|
const OpXderefType : UInt = 0xA7U

///|
const OpConvert : UInt = 0xA8U

///|
const OpReinterpret : UInt = 0xA9U

///|
/// Basic type encodings -- the value for AttrEncoding in a TagBaseType Entry.
const EncAddress : Int64 = 0x01

///|
const EncBoolean : Int64 = 0x02

///|
const EncComplexFloat : Int64 = 0x03

///|
const EncFloat : Int64 = 0x04

///|
const EncSigned : Int64 = 0x05

///|
const EncSignedChar : Int64 = 0x06

///|
const EncUnsigned : Int64 = 0x07

///|
const EncUnsignedChar : Int64 = 0x08
/// DWARF 3

///|
const EncImaginaryFloat : Int64 = 0x09

///|
const EncPackedDecimal : Int64 = 0x0A

///|
const EncNumericString : Int64 = 0x0B

///|
const EncEdited : Int64 = 0x0C

///|
const EncSignedFixed : Int64 = 0x0D

///|
const EncUnsignedFixed : Int64 = 0x0E

///|
const EncDecimalFloat : Int64 = 0x0F
/// DWARF 4

///|
const EncUtf : Int64 = 0x10
/// DWARF 5

///|
const EncUcs : Int64 = 0x11

///|
const EncAscii : Int64 = 0x12

///|
/// Statement program standard opcode encodings.
const LnsCopy : UInt = 1U

///|
const LnsAdvancePc : UInt = 2U

///|
const LnsAdvanceLine : UInt = 3U

///|
const LnsSetFile : UInt = 4U

///|
const LnsSetColumn : UInt = 5U

///|
const LnsNegateStmt : UInt = 6U

///|
const LnsSetBasicBlock : UInt = 7U

///|
const LnsConstAddPc : UInt = 8U

///|
const LnsFixedAdvancePc : UInt = 9U
/// DWARF 3

///|
const LnsSetPrologueEnd : UInt = 10U

///|
const LnsSetEpilogueBegin : UInt = 11U

///|
const LnsSetISA : UInt = 12U

///|
/// Statement program extended opcode encodings.
const LneEndSequence : UInt = 1U

///|
const LneSetAddress : UInt = 2U

///|
const LneDefineFile : UInt = 3U
/// DWARF 4

///|
const LneSetDiscriminator : UInt = 4U

///|
/// Line table directory and file name entry formats.
/// These are new in DWARF 5.
const LnctPath : UInt = 0x01U

///|
const LnctDirectoryIndex : UInt = 0x02U

///|
const LnctTimestamp : UInt = 0x03U

///|
const LnctSize : UInt = 0x04U

///|
const LnctMD5 : UInt = 0x05U

///|
/// Location list entry codes.
/// These are new in DWARF 5.
const LleEndOfList : UInt = 0x00U

///|
const LleBaseAddressx : UInt = 0x01U

///|
const LleStartxEndx : UInt = 0x02U

///|
const LleStartxLength : UInt = 0x03U

///|
const LleOffsetPair : UInt = 0x04U

///|
const LleDefaultLocation : UInt = 0x05U

///|
const LleBaseAddress : UInt = 0x06U

///|
const LleStartEnd : UInt = 0x07U

///|
const LleStartLength : UInt = 0x08U

///|
/// Unit header unit type encodings.
/// These are new in DWARF 5.
const UtCompile : UInt = 0x01U

///|
const UtType : UInt = 0x02U

///|
const UtPartial : UInt = 0x03U

///|
const UtSkeleton : UInt = 0x04U

///|
const UtSplitCompile : UInt = 0x05U

///|
const UtSplitType : UInt = 0x06U

///|
/// Opcodes for DWARFv5 debug_rnglists section.
const RleEndOfList : UInt = 0x0U

///|
const RleBaseAddressx : UInt = 0x1U

///|
const RleStartxEndx : UInt = 0x2U

///|
const RleStartxLength : UInt = 0x3U

///|
const RleOffsetPair : UInt = 0x4U

///|
const RleBaseAddress : UInt = 0x5U

///|
const RleStartEnd : UInt = 0x6U

///|
const RleStartLength : UInt = 0x7U
