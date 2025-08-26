from julia import Main

range_str = "0:0.1:2.0"
try:
    saveat_julia = Main.eval(range_str)
    print(f"Constructed Julia Range for saveat: {saveat_julia}")
except Exception as e:
    print(f"Error during Main.eval(range_str): {e}")
