import { Typography } from "@mui/material";
import BootstrapInput from "./bootstrapInput";

// eslint-disable-next-line react/prop-types
const CustomTextField = ({ label, required, style, adornment, dir, ...props }) => {
  const defaultFieldStyle = {
    my: 1,
    height: "58px",
    width: "100%",
    color: "#001c32",
    backgroundColor: "#F6F6F6",
    borderRadius: "6px",
    "& .MuiOutlinedInput-root": {
      borderRadius: "6px",
      "& fieldset": {
        border: "none",
      },
      "&:hover fieldset": {
        border: "none",
      },
      "&.Mui-focused fieldset": {
        border: "1px solid #05566F",
      },
    },
    input: {
      color: "#001c32",
      direction: dir || "rtl",
    },
  };

  return (
    <div>
      <Typography
        variant="body1"
        color="#000000DE"
        sx={{
          fontFamily: "El Messiri",
          fontSize: "16px",
          fontWeight: "600",
          textAlign: "right",
        }}
      >
        {label} {required && <span style={{ color: "red" }}>*</span>}
      </Typography>
      {/* <BootstrapInput {...props} sx={{ ...defaultFieldStyle, ...style }} /> */}

      {adornment ? (
        <BootstrapInput
          {...props}
          endAdornment={adornment}
          sx={{ ...defaultFieldStyle, ...style }}
        />
      ) : (
        <BootstrapInput
          {...props}
          sx={{ ...defaultFieldStyle, ...style }}
        />
      )}
    </div>
  );
};

export default CustomTextField;
