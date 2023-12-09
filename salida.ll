; ModuleID = 'miModulo'
source_filename = "miModulo"
target triple = "x86_64-pc-linux-gnu"

@a = global i32 5
@formatString = private unnamed_addr constant [28 x i8] c"El valor del entero es: %d\0A\00", align 1
@stringConstant = private unnamed_addr constant [4 x i8] c"Bye\00", align 1

define i32 @main() {
entry:
  br label %loopCondition
  ret i32 0

loopCondition:                                    ; preds = %loopBody, %entry
  %loadedValue = load i32, i32* @a, align 4
  %cmpResult = icmp ult i32 %loadedValue, 10
  br i1 %cmpResult, label %loopBody, label %exit

loopBody:                                         ; preds = %loopCondition
  %loadedValue1 = load i32, i32* @a, align 4
  %1 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @formatString, i32 0, i32 0), i32 %loadedValue1)
  %currentValue = load i32, i32* @a, align 4
  %incrementedValue = add i32 %currentValue, 1
  store i32 %incrementedValue, i32* @a, align 4
  br label %loopCondition

exit:                                             ; preds = %loopCondition
  %2 = call i32 @puts(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @stringConstant, i32 0, i32 0))
  ret i32 0
}

declare i32 @printf(i8*, ...)

declare i32 @puts(i8*)

