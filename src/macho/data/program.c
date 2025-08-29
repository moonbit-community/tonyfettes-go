#include <stdio.h>
#include <stdlib.h>

int add_numbers(int a, int b) { return a + b; }

const char *get_greeting() { return "Hello from Mach-O!"; }

// Main function
int main() {
  int result = add_numbers(42, 13);
  printf("%s\n", get_greeting());
  printf("The answer is: %d\n", result);
  return 0;
}
