#include "EdRuntime/HiEditorDataComponent.h"


UHiEditorDataComponent::UHiEditorDataComponent(const FObjectInitializer& ObjectInitializer)
{
	bWantsInitializeComponent = true;
}

void UHiEditorDataComponent::InitializeComponent()
{
	Super::InitializeComponent();
	OnInitializeComponent();
}

void UHiEditorDataComponent::UninitializeComponent()
{
	Super::UninitializeComponent();
	OnUninitializeComponent();
}

void UHiEditorDataComponent::BeginPlay()
{
	Super::BeginPlay();
}
