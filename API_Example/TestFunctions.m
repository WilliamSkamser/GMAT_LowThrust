fm = gmat.gmat.Construct("ForceModel", "FM")
fm.SetField("CentralBody", "Earth")

earthgrav = gmat.gmat.Construct("GravityField")
earthgrav.SetField("BodyName","Earth")
earthgrav.SetField("Degree",8)
earthgrav.SetField("Order",8)

fm.AddForce(earthgrav)
