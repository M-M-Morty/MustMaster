// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiSubAreaTriggerComponent.h"

#if WITH_EDITOR
#include "HiWorldSoundPrimaryDataAsset.h"

void UHiSubAreaTriggerComponent::PreEditChange(FProperty* PropertyAboutToChange)
{
	Super::PreEditChange(PropertyAboutToChange);
	if (PropertyAboutToChange)
	{
		const FName& PropertyName = PropertyAboutToChange->GetFName();
		if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiSubAreaTriggerComponent, BGM) )
		{
			if (IsValid(BGM))
			{
				BGM->OwnerComponent = nullptr;
				BGM->MarkPackageDirty();	
			}			
		}

		else if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiSubAreaTriggerComponent, AmbientSound) )
		{
			if (IsValid(AmbientSound))
			{
				AmbientSound->OwnerComponent = nullptr;
				AmbientSound->MarkPackageDirty();	
			}			
		}	
	}
}

void UHiSubAreaTriggerComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);	
	if (PropertyChangedEvent.Property)
	{
		const FName& PropertyName = PropertyChangedEvent.Property->GetFName();
		if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiSubAreaTriggerComponent, BGM))
		{
			if (IsValid(BGM))
			{
				BGM->OwnerComponent = this;
				BGM->MarkPackageDirty();	
			}			
		}		
		else if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiSubAreaTriggerComponent, AmbientSound))
		{
			if (IsValid(AmbientSound))
			{
				AmbientSound->OwnerComponent = this;
				AmbientSound->MarkPackageDirty();	
			}			
		}
	}	
}
#endif