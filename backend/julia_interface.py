from julia import Main, Julia
import logging
from schemas import IVTInput
from pathlib import Path 



# Initialize Julia
jl = Julia(compiled_modules=False)

# Initialize logging
logging.basicConfig(level=logging.INFO)

# Include the Julia module containing IVT_CSTR
#Main.include("C:/Users/User/mRNAdigitalTwin/IVT2.0/modules/API/reactorAPI.jl")
ROOT = Path(__file__).resolve().parents[1]  # .../mRNAdigitalTwin
API_FILE = ROOT / "IVT2.0" / "modules" / "API" / "reactorAPI.jl"
Main.include(API_FILE.as_posix()) 

def run_ivt_process(input_data: IVTInput):
    try:
        logging.info("Calling Julia function IVT_CSTR with input data...")
        logging.info(f"T7RNAP: {input_data.T7RNAP}, ATP: {input_data.ATP}, UTP: {input_data.UTP}, CTP: {input_data.CTP}, GTP: {input_data.GTP}, Mg: {input_data.Mg}, DNA: {input_data.DNA}, Q: {input_data.Q}, V: {input_data.V}")


        # Handle 'saveat_step'
        step = input_data.saveat_step if input_data.saveat_step else 0.1
        final_time = input_data.finaltime

        logging.info(f"Constructing Julia Range for saveat with step: {step}, final_time: {final_time}")

        # Construct Julia Range string
        range_str = f"0:{step}:{final_time}"
        logging.info(f"Constructing Julia Range for saveat: {range_str}")

        # Evaluate the Range in Julia
        saveat_julia = Main.eval(range_str)
        logging.info(f"Constructed Julia Range for saveat: {saveat_julia}")

        # try:
        #     saveat_julia = Main.eval(range_str)
        #     logging.info(f"Constructed Julia Range for saveat: {saveat_julia}")
        # except Exception as e:
        #     logging.error(f"Error during Main.eval(range_str): {str(e)}")
        #     raise


        # Call IVT_CSTR with all arguments
        t, sol, outputs = Main.IVT_CSTR(
            input_data.T7RNAP, 
            input_data.ATP, 
            input_data.UTP,
            input_data.CTP, 
            input_data.GTP, 
            input_data.Mg,
            input_data.DNA, 
            input_data.Q, 
            input_data.V,  
            final_time=final_time,
            saveat=saveat_julia
        )
        
        logging.info(f"Received time: {t}")
        logging.info(f"Received outputs from Julia: {outputs}")
        

        result = {
            "time": [float(ti) for ti in t],
            "ATPo": [float(v) for v in outputs.ATP],
            "UTPo": [float(v) for v in outputs.UTP],
            "CTPo": [float(v) for v in outputs.CTP],
            "GTPo": [float(v) for v in outputs.GTP],
            "Phosphateo": [float(v) for v in outputs.Phosphate],
            "pHo": [float(v) for v in outputs.pH],
            "TotalMgo": [float(v) for v in outputs.TotalMg],
            "TotalRNAo": [float(v) for v in outputs.TotalRNA],
        }
        
        # result =  {
        #     "time": list(t),
        #     "ATPo": outputs.ATP,
        #     "UTPo": outputs.UTP,
        #     "CTPo": outputs.CTP,
        #     "GTPo": outputs.GTP,
        #     "Phosphateo": outputs.Phosphate,
        #     "pHo": outputs.pH,
        #     "TotalMgo": outputs.TotalMg,
        #     "TotalRNAo": outputs.TotalRNA,
        # }
        logging.info(f"Received result: {result}")

        return result

    except Exception as e:
        logging.error(f"Error calling Julia function: {str(e)}")
        return {"error": str(e)}
