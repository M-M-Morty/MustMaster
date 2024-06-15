#pragma once

#include "Math/Vector.h"

#include "MathHelper.generated.h"

UCLASS(meta=(BlueprintThreadSafe, ScriptName = "MathHelper"))
class HIGAME_API UMathHelper : public UBlueprintFunctionLibrary
{
	GENERATED_UCLASS_BODY()
public:
	inline static void DecomposeVector(FVector& normalCompo, FVector& tangentCompo, const FVector& outwardDir, const FVector& outwardNormal)
	{
		normalCompo = outwardNormal * (outwardDir.Dot(outwardNormal));
		tangentCompo = outwardDir - normalCompo;
	}

	UFUNCTION(BlueprintPure, Category="MathHelper")
	static float FAngleNormalized(float Current)
	{
		float Target = Current - 360 * int(Current/360);
		if (Target > 180)
		{
			Target -= 360;
		}
		else if (Target < -180)
		{
			Target += 360;
		}
		return Target;
	}

	UFUNCTION(BlueprintPure, Category="MathHelper")
	static float FAngleNearestInterpTo(float Current, float Target, float DeltaTime, float InterpSpeed)
	{
		while (Target - Current > 180)
		{
			Target -= 360;
		}
		while (Target - Current < -180)
		{
			Target += 360;
		}
		return FMath::Wrap(FMath::FInterpTo(Current, Target, DeltaTime, InterpSpeed), 0.0f, 360.0f);
	}

	UFUNCTION(BlueprintPure, Category="MathHelper")
	static float FAngleNearestInterpConstantTo(float Current, float Target, float DeltaTime, float InterpSpeed)
	{
		while (Target - Current > 180)
		{
			Target -= 360;
		}
		while (Target - Current < -180)
		{
			Target += 360;
		}
		return FMath::Wrap(FMath::FInterpConstantTo(Current, Target, DeltaTime, InterpSpeed), 0.0f, 360.0f);
	}

	UFUNCTION(BlueprintPure, Category="MathHelper")
	static FRotator RNearestInterpTo(const FRotator& Current, const FRotator& Target, float DeltaTime, float InterpSpeed)
	{
		FRotator Result;
		Result.Pitch = FAngleNearestInterpTo(Current.Pitch, Target.Pitch, DeltaTime, InterpSpeed);
		Result.Yaw = FAngleNearestInterpTo(Current.Yaw, Target.Yaw, DeltaTime, InterpSpeed);
		Result.Roll = FAngleNearestInterpTo(Current.Roll, Target.Roll, DeltaTime, InterpSpeed);
		return Result;
	}

	UFUNCTION(BlueprintPure, Category="MathHelper")
	static FRotator RNearestInterpConstantTo(const FRotator& Current, const FRotator& Target, float DeltaTime, float InterpSpeed)
	{
		FRotator Result;
		Result.Pitch = FAngleNearestInterpConstantTo(Current.Pitch, Target.Pitch, DeltaTime, InterpSpeed);
		Result.Yaw = FAngleNearestInterpConstantTo(Current.Yaw, Target.Yaw, DeltaTime, InterpSpeed);
		Result.Roll = FAngleNearestInterpConstantTo(Current.Roll, Target.Roll, DeltaTime, InterpSpeed);
		return Result;
	}
};
