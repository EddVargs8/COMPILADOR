; ModuleID = 'miModulo'
source_filename = "miModulo"
target triple = "x86_64-pc-linux-gnu"

define i32 @main() {
entry:
  %a = alloca i32, align 4
  %b = alloca double, align 8
  %c = alloca i8*, align 8
  ret i32 69
}

