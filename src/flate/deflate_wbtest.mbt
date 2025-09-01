///|
test "test_token_creation" {
  let lit_token = literal_token(65)
  @json.inspect(lit_token.literal(), content=65)
  let match_token = match_token(10, 5)
  @json.inspect(match_token.length(), content=10)
  @json.inspect(match_token.offset(), content=5)
}
