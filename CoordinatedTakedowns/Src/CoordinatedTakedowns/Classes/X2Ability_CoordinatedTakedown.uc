class X2Ability_CoordinatedTakedown
		extends X2Ability 
		config(CoordinatedTakedowns);

//------------------------------------------------------------------
//***********************CREATE TEMPLATES***************************
//------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	Templates.AddItem(AddMarkForTakedownAbility());
	Templates.AddItem(AddMarkForTakedownSniperAbility());
	Templates.AddItem(AddMarkForTakedownPistolAbility());
	Templates.AddItem(AddTakedownShotAbility());
	Templates.AddItem(AddTakedownShotPistolAbility());
	return Templates;
}

static function X2AbilityTemplate CreateTakedownCommonProperties(name AbilityName)
{
//used variables	
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2Effect_SetUnitValue             UnitValueEffect;
	local X2Effect_MarkForTakedown			TakedownMarkEffect;			//shooting checks whether this effect is on the targets
	local X2Condition_UnitEffects           SuppressedCondition;
	local X2Condition_Visibility			VisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
//Icon Properties
	Template.bDontDisplayInAbilitySummary = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailableOrNoTargets;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY+1;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

//Conditions:
//user alive
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
//has ammo
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;                  //  ammo is consumed by the shot, not by this, but this should verify ammo is available
	Template.AbilityCosts.AddItem(AmmoCost);
//is not suppressed
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
//target is visible
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireGameplayVisible = true;
	VisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);
//target is a living enemy
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

//Additional behavior when selected
// Targeting Method
	Template.AbilityTargetStyle = default.SimpleSingleTarget; // Only at single targets that are in range.
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	//Template.bUsesFiringCamera = true; //needed?
//TODO: make some visual feedback, check how overwatch displays the popup text overhead
	//	Template.CinescriptCameraType = "StandardGunFiring"; 
	//note: X2Effect_MarkForTakedown takes care of effect application regardless of hit/miss
	Template.AbilityToHitCalc = default.SimpleStandardAim;
	Template.AbilityToHitOwnerOnMissCalc = default.SimpleStandardAim;
//sets up ConcealedOverwatch if soldier is concealed(nnope, concealed OW works without this code)
/*	
	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = 'ConcealedOverwatch';
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);
*/

//Ability gameplay effects
//doesn't reveal soldier(this is only mark, not shoot)
	Template.Hostility = eHostility_Neutral;
	//Template.bIsPassive = true; //why was this enabled?
	//bAllowedByDefault;		//  if true, this ability will be enabled by default. Otherwise the ability will have to be enabled before it is usable
	//AdditionalAbilities		//  when a unit is granted this ability, it will be granted all of these abilities as well
	//PostActivationEvents;     //  trigger these events after AbilityActivated is triggered (only when not interrupted) EventData=ability state, EventSource=owner unit state
//place the mark on the target
	TakedownMarkEffect = new class'X2Effect_MarkForTakedown';
	TakedownMarkEffect.BuildPersistentEffect(1, true, true,, eGameRule_TacticalGameStart);
	TakedownMarkEffect.SetDisplayInfo(ePerkBuff_Passive,
										Template.LocFriendlyName,
										Template.GetMyLongDescription(),
										Template.IconImage,
										true, , Template.AbilitySourceName);
	Template.AddTargetEffect(TakedownMarkEffect);

//Set it up in the game
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}


//------------------------------------------------------------------
//***********************STANDARD WEAPONS***************************
//------------------------------------------------------------------
static function X2AbilityTemplate AddMarkForTakedownAbility(){
//used variables
	local X2AbilityTemplate                 Template;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs
	local X2AbilityCost_ActionPoints        ActionPointCost;

	Template = CreateTakedownCommonProperties('MarkForTakedown');

//reserve TakedownActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);
//has ActionPoints
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	Template.AbilityCosts.AddItem(ActionPointCost);

	return Template;
}

//------------------------------------------------------------------
//*************************SNIPER WEAPONS***************************
//------------------------------------------------------------------

static function X2AbilityTemplate AddMarkForTakedownSniperAbility(){
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs

	Template = CreateTakedownCommonProperties('MarkForTakedownSniper');

	//Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_snipershot";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY+1;

//Conditions:
//sniper fire conditions
	// Action Point (cannot use it after moving)
	ActionPointCost = new class 'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 2;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
//currently doesnt support snap shot
	//...
//reserve TakedownActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);


	return Template;
}

//------------------------------------------------------------------
//*************************PISTOL WEAPONS***************************
//------------------------------------------------------------------

static function X2AbilityTemplate AddMarkForTakedownPistolAbility(){
	local X2AbilityTemplate                 Template;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs
	local X2AbilityCost_ActionPoints        ActionPointCost;

	Template = CreateTakedownCommonProperties('MarkForTakedownPistol');

	//Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PISTOL_OVERWATCH_PRIORITY+1;

//reserve TakedownActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownPistolActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);
//Conditions:
//has ActionPoints
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	Template.AbilityCosts.AddItem(ActionPointCost);

	return Template;
}


//------------------------------------------------------------------
//*************************TAKEDOWN SHOT****************************
//------------------------------------------------------------------



static function X2AbilityTemplate CreateTakedownShotCommonProperties(name AbilityName){
	local X2AbilityTemplate								Template;	
	local X2AbilityToHitCalc_StandardAim				StandardAim;
	local X2Condition_UnitProperty						ShooterCondition;
	local X2AbilityTarget_Single						SingleTarget;
	local X2Effect_Knockback							KnockbackEffect;
	local X2Condition_UnitEffectsWithAbilitySource		AbilitySourceCondition; //this check whether the target was marked by us

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	//Icon Properties
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;
	Template.DisplayTargetHitChance = false;

//Conditions:
//is alive
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
//is concealed
	/*
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.IsConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);
	*/
//target is already marked by this soldier
	AbilitySourceCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	AbilitySourceCondition.AddRequireEffect(class'X2Effect_MarkForTakedown'.default.EffectName, 'AA_UnitIsMarkedForTakedown');
	Template.AbilityTargetConditions.Additem(AbilitySourceCondition);
// Can't target dead; Can't target friendlies
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
//not needed, but maybe need to modify it to use with my mark
	//Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty); 


//Ability gameplay effects
//Acquire target (only single target within weapon range)
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;
//calculate aim
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityToHitOwnerOnMissCalc = StandardAim;
//extra shot effects
//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = false;	
	Template.bAllowAmmoEffects = true;
// Damage Effect
	//Template.AddTargetEffect(default.WeaponUpgradeMissDamage);
	Template.AssociatedPassives.AddItem('HoloTargeting'); // marks to gain the aim bonus?


//visuals (knockback)
	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	KnockbackEffect.bUseTargetLocation = true;
	Template.AddTargetEffect(KnockbackEffect);
//Set it up in the game
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}



static function X2AbilityTemplate AddTakedownShotAbility(){
//used variables
	local X2AbilityTemplate								Template;
	local X2AbilityCost_Ammo							AmmoCost;
	local X2AbilityCost_ReserveActionPoints				ReserveActionPointCost;
	local X2Condition_Visibility						TargetVisibilityCondition;

//set up common properties
	Template = CreateTakedownShotCommonProperties( 'TakedownShot' );

//Conditions:
//has ammo
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
//has ReservedActionPoints (the shot is ready and waiting for a trigger event)
	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);
//target is visible
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireBasicVisibility = true; //LOS + in range
	TargetVisibilityCondition.bRequireGameplayVisible = true; //LOS + in range + meets situational conditions in interface method UpdateGameplayVisibility
	TargetVisibilityCondition.bAllowSquadsight = true;        //LOS + any squadmate can see the target, if unit has Squadsight (overrides bRequireGameplayVisible)
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	return Template;	
}


//------------------------------------------------------------------
//****************************PISTOLS*******************************
//------------------------------------------------------------------

static function X2AbilityTemplate AddTakedownShotPistolAbility()
{
	//used variables
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ReserveActionPoints		ReserveActionPointCost;
	local X2Condition_Visibility				TargetVisibilityCondition;

//set up common properties
	Template = CreateTakedownShotCommonProperties( 'TakedownShotPistol' );

	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2Effect_ReserveTakedownActionPoints'.default.TakedownPistolActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireBasicVisibility = true; //LOS + in range
	TargetVisibilityCondition.bRequireGameplayVisible = true; //LOS + in range + meets situational conditions in interface method UpdateGameplayVisibility
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	return Template;
}


//------------------------------------------------------------------
//****************************SNIPERS*******************************
//------------------------------------------------------------------






static simulated function OverwatchAbility_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local X2Action_CameraFrameAbility FrameAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local UnitValue EverVigilantValue;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local string FlyOverText, FlyOverImage;
	local XGUnit UnitVisualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);

	// Only turn the camera on the overwatcher if it is visible to the local player.
	if( !`XENGINE.IsMultiPlayerGame() || class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(UnitState.ObjectID, VisualizeGameState.HistoryIndex) )
	{
		FrameAction = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTrack(BuildTrack, Context));
		FrameAction.AbilityToFrame = Context;
	}
					
	if (UnitState != none && UnitState.GetUnitValue(class'X2Ability_SpecialistAbilitySet'.default.EverVigilantEffectName, EverVigilantValue) && EverVigilantValue.fValue > 0)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('EverVigilant');
		if (UnitState.HasSoldierAbility('CoveringFire'))
			FlyOverText = class'XLocalizedData'.default.EverVigilantWithCoveringFire;
		else
			FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else if (UnitState != none && UnitState.HasSoldierAbility('CoveringFire'))
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('CoveringFire');
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));

	if (UnitState != none)
	{
		UnitVisualizer = XGUnit(UnitState.GetVisualizer());
		if( (UnitVisualizer != none) && !UnitVisualizer.IsMine())
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundUI.OverwatchCue', FlyOverText, 'Overwatch', eColor_Bad, FlyOverImage);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, 'Overwatch', eColor_Good, FlyOverImage);
		}
	}
	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
}

