// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAppearanceMod.h"
#include "UObject/UnrealTypePrivate.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Characters/HiCharacter.h"

// Sets default values for this component's properties
UHiAppearanceMod::UHiAppearanceMod()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = false;

	// ...
}


// Called when the game starts
void UHiAppearanceMod::BeginPlay()
{
	Super::BeginPlay();
	
	AHiCharacter* Owner = Cast<AHiCharacter>(GetOwner());
	if (Owner)
	{
		AnimIns = Owner->GetMesh()->GetAnimInstance();

		UHiAnimInstance* MyAnimIns = Cast<UHiAnimInstance>(AnimIns);

		if (MyAnimIns && InsertModBlueprint)
		{
			MyAnimIns->LinkAnimGraphByTag("InserModABP", InsertModBlueprint);
			MyAnimIns->OpenInsert(BlendInTime);
		}
	}
	
	// ...
	
}
/**
 * Ends gameplay for this component.
 * Called from AActor::EndPlay only if bHasBegunPlay is true
 */
void UHiAppearanceMod::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	UHiAnimInstance* MyAnimIns = Cast<UHiAnimInstance>(AnimIns);
	if (MyAnimIns)
	{
		MyAnimIns->CloseInsert(BlendOutTime);
		MyAnimIns->LinkAnimGraphByTag("InserModABP", nullptr);
	}
	// ...

}


// Called every frame
void UHiAppearanceMod::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}



