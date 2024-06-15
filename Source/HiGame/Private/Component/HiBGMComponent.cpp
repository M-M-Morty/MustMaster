// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiBGMComponent.h"

#if WITH_EDITOR
#include "HiWorldSoundPrimaryDataAsset.h"

void UHiBGMComponent::PreEditChange(FProperty* PropertyAboutToChange)
{
	Super::PreEditChange(PropertyAboutToChange);
	if (PropertyAboutToChange)
	{
		const FName& PropertyName = PropertyAboutToChange->GetFName();
		if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiBGMComponent, BGM) )
		{
			if (IsValid(BGM))
			{
				BGM->OwnerComponent = nullptr;
				BGM->Owner = nullptr;
            	BGM->MarkPackageDirty();	
			}			
		}
		else if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiBGMComponent, AmbientSound) )
		{
			if (IsValid(AmbientSound))
			{
				AmbientSound->OwnerComponent = nullptr;
				AmbientSound->Owner = nullptr;
				AmbientSound->MarkPackageDirty();	
			}			
		}	
	}
}

void UHiBGMComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);	
	if (PropertyChangedEvent.Property)
	{
		const FName& PropertyName = PropertyChangedEvent.Property->GetFName();
		if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiBGMComponent, BGM))
		{
			if (IsValid(BGM))
			{
				BGM->OwnerComponent = this;
				BGM->Owner = this->GetOwner();
				BGM->MarkPackageDirty();	
			}			
		}
		else if (PropertyName == GET_MEMBER_NAME_CHECKED(UHiBGMComponent, AmbientSound))
		{
			if (IsValid(AmbientSound))
			{
				AmbientSound->OwnerComponent = this;
				AmbientSound->Owner = this->GetOwner();
				AmbientSound->MarkPackageDirty();	
			}			
		}
	}	
}
#endif