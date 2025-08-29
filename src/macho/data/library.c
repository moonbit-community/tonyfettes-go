#include <stdio.h>

int multiply(int a, int b) { return a * b; }

static int counter = 0;

int increment_counter() { return ++counter; }

void print_info(const char *message) { printf("Library says: %s\n", message); }
