; ModuleID = 'miModulo'
source_filename = "miModulo"
target triple = "x86_64-pc-linux-gnu"

@a = global i32 22
@b = global i32 1
@stringConstant = private unnamed_addr constant [6 x i8] c"Mayor\00", align 1
@stringConstant.1 = private unnamed_addr constant [6 x i8] c"Menor\00", align 1
@formatString = private unnamed_addr constant [28 x i8] c"El valor del entero es: %d\0A\00", align 1

define i32 @main() {
entry:
  %loadedValue = load i32, i32* @a, align 4
  %cmpResult = icmp uge i32 %loadedValue, 18
  br i1 %cmpResult, label %ifBlock, label %elseBlock
  br label %loopCondition
  ret i32 0

ifBlock:                                          ; preds = %entry
  %2 = call i32 @puts(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @stringConstant, i32 0, i32 0))
  br label %exitBlock

elseBlock:                                        ; preds = %entry
  %3 = call i32 @puts(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @stringConstant.1, i32 0, i32 0))
  br label %exitBlock

exitBlock:                                        ; preds = %elseBlock, %ifBlock
  br label %loopCondition

loopCondition:                                    ; preds = %exitBlock, %loopBody, %entry
  %loadedValue1 = load i32, i32* @b, align 4
  %cmpResult2 = icmp ule i32 %loadedValue1, 10
  br i1 %cmpResult2, label %loopBody, label %exit

loopBody:                                         ; preds = %loopCondition
  %loadedValue3 = load i32, i32* @b, align 4
  %4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @formatString, i32 0, i32 0), i32 %loadedValue3)
  %currentValue = load i32, i32* @b, align 4
  %incrementedValue = add i32 %currentValue, 1
  store i32 %incrementedValue, i32* @b, align 4
  br label %loopCondition

exit:                                             ; preds = %loopCondition
  ret i32 0
}

declare i32 @puts(i8*)

declare i32 @printf(i8*, ...)

