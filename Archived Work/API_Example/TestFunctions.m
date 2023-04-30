load_gmat();
gmat.gmat.Clear()

% Force model settings
fm = GMATAPI.Construct("ForceModel", "FM");
fm.SetField("CentralBody", "Earth");

% An 8x8 JGM-3 Gravity Model.  No name set, so management resides with the user
earthgrav = GMATAPI.Construct("GravityField");
earthgrav.SetField("BodyName","Earth");
earthgrav.SetField("PotentialFile","../data/gravity/earth/JGM3.cof");
earthgrav.SetField("Degree",8);
earthgrav.SetField("Order",8);

% Add force into the dynamics model.  Here we pass ownership to the force model
fm.AddForce(earthgrav);

gmat.gmat.Clear()