local P,R,W=game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local L=P.LocalPlayer
for _,v in pairs(L:WaitForChild("Backpack"):GetChildren())do if v.Name=="🧗 Climb"then v:Destroy()end end
if L.PlayerGui:FindFirstChild("FEClimbHUD")then L.PlayerGui.FEClimbHUD:Destroy()end
if W:FindFirstChild("FEC_AnimRig")then W.FEC_AnimRig:Destroy()end

getgenv().FEC={active=false,grabbed=false,mode="Sticks",autoVault=true,atLedge=false,vaulting=false,vaultT=0,vStart=CFrame.new(),vEnd=CFrame.new(),turnT=0,phase=0,wNorm=Vector3.new(0,0,1),smoothNorm=Vector3.new(0,0,1),handL=Vector3.zero,handR=Vector3.zero,posL=Vector3.zero,posR=Vector3.zero,spLimbs={},dragL=false,dragR=false,dL=Vector2.zero,dR=Vector2.zero,joyL=Vector2.zero,joyR=Vector2.zero,ap=nil,ao=nil,att=nil,rig=nil,rigJ={},tracks={},cursors={},lbl=nil,modeBtn=nil,vaultBtn=nil,padL=nil,padR=nil,stickL=nil,stickR=nil,pullBtn=nil,jmpBtn=nil,gui=nil}
local S=getgenv().FEC

function S.setControls(on)
 pcall(function()local c=require(L.PlayerScripts:WaitForChild("PlayerModule")):GetControls()if on then c:Enable()else c:Disable()end end)
 pcall(function()local g=L.PlayerGui:FindFirstChild("TouchGui")if g then g.Enabled=on end end)
end

function S.clearPhys()if S.ap then S.ap:Destroy()S.ap=nil end if S.ao then S.ao:Destroy()S.ao=nil end if S.att then S.att:Destroy()S.att=nil end end
function S.clearRig()if S.rig then S.rig:Destroy()S.rig=nil end S.rigJ={}end
function S.clearCursors()for _,p in pairs(S.cursors)do if p then p:Destroy()end end S.cursors={}end

function S.makeCursors()
 S.clearCursors()
 local function r(nm,col)local p=Instance.new("Part",W)p.Name,p.Shape,p.Size,p.Material,p.Color,p.Transparency,p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=nm,Enum.PartType.Cylinder,Vector3.new(0.08,1.35,1.35),Enum.Material.Neon,col,0.35,true,false,false,false return p end
 S.cursors={L=r("FEC_CL",Color3.fromRGB(90,210,255)),R=r("FEC_CR",Color3.fromRGB(255,115,115))}
end

function S.makeRig(c)
 S.clearRig()c.Archivable=true local cl=c:Clone()c.Archivable=false if not cl then return end cl.Name="FEC_AnimRig"
 for _,d in ipairs(cl:GetDescendants())do if d:IsA("BasePart")then d.Transparency,d.CanCollide,d.Massless,d.CanQuery,d.CanTouch=1,false,true,false,false elseif d:IsA("Decal")or d:IsA("Texture")then d.Transparency=1 elseif d:IsA("Script")or d:IsA("LocalScript")or d:IsA("Sound")or d:IsA("Animator")then d:Destroy()end end
 local rHr,rH=cl:FindFirstChild("HumanoidRootPart"),cl:FindFirstChildOfClass("Humanoid")if rHr then rHr.Anchored=true end if rH then rH.PlatformStand,rH.DisplayDistanceType=true,Enum.HumanoidDisplayDistanceType.None end
 cl.Parent=W S.rig=cl for _,n in ipairs({"Root","Waist","Neck","LeftShoulder","RightShoulder","LeftElbow","RightElbow","LeftHip","RightHip","LeftKnee","RightKnee"})do S.rigJ[n]=cl:FindFirstChild(n,true)end
end

function S.makePhys(hr)
 S.clearPhys()local att=Instance.new("Attachment",hr)
 local ap=Instance.new("AlignPosition",hr)ap.Mode,ap.Attachment0,ap.MaxForce,ap.MaxVelocity,ap.Responsiveness,ap.Position=Enum.PositionAlignmentMode.OneAttachment,att,1e6,240,75,hr.Position
 local ao=Instance.new("AlignOrientation",hr)ao.Mode,ao.Attachment0,ao.MaxTorque,ao.Responsiveness,ao.CFrame=Enum.OrientationAlignmentMode.OneAttachment,att,1e6,75,hr.CFrame
 S.att,S.ap,S.ao=att,ap,ao
end

function S.resetState(c)
 S.grabbed,S.atLedge,S.vaulting,S.vaultT,S.turnT,S.dragL,S.dragR,S.dL,S.dR,S.joyL,S.joyR=false,false,false,0,0,false,false,Vector2.zero,Vector2.zero,Vector2.zero,Vector2.zero S.spLimbs={}
 for _,v in pairs({S.padL,S.padR,S.stickL,S.stickR})do if v then v.Visible=false end end
 S.clearCursors()S.clearPhys()S.clearRig()S.setControls(true)if S.stopTracks then S.stopTracks()end if not c then return end
 local h,hr,an=c:FindFirstChildOfClass("Humanoid"),c:FindFirstChild("HumanoidRootPart"),c:FindFirstChild("Animate")
 if hr then hr.Anchored=false hr.AssemblyLinearVelocity,hr.AssemblyAngularVelocity=Vector3.zero,Vector3.zero end
 if an then an.Disabled=false end if h then h:SetStateEnabled(12,true)h.PlatformStand,h.AutoRotate=false,true end
 for _,d in pairs(c:GetDescendants())do if d:IsA("Motor6D")then d.Transform=CFrame.new()end end
end
print("Part 1 Loaded!")
