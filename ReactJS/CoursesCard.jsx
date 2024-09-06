import { useNavigate } from "react-router-dom";
import { Box, Button, Stack, Typography, useMediaQuery } from "@mui/material";
import CircularProgress, {
  circularProgressClasses,
} from "@mui/material/CircularProgress";
import KeyboardBackspaceIcon from "@mui/icons-material/KeyboardBackspace";
import TheatersIcon from "@mui/icons-material/Theaters";
import LockIcon from "@mui/icons-material/Lock";
import PropTypes from "prop-types";

const CoursesCard = ({ course, user }) => {
  const navigate = useNavigate();
  const is780To1280 = useMediaQuery(
    "(min-width: 510px) and (max-width: 1400px)"
  );

  const isCourseLocked = course?.locked_for_user;

  const completed_activities = course?.completed_activities?.filter(
    (activity) => activity?.user_id === user?.id
  );

  const circularProgress =
    (completed_activities?.length / course?.no_of_activities) * 100 || 0;

  const actionText = () => {
    if (course?.is_published) {
      return isCourseLocked ? "مقفل" : "الدخول للدورة";
    } else {
      if (course?.is_user_registered) {
        return "الدخول للدورة";
      } else if (isCourseLocked || !isCourseLocked) {
        return "التسجيل غير متاح لاكتمال العدد";
      }
    }
  };

  const handleCourseClick = () => {
    if (course?.is_published || course?.is_user_registered) {
      navigate(`/courses/${course?.id}`);
    } else {
      return;
    }
  };

  return (
    <Box
      p={2}
      dir="rtl"
      sx={{
        background: isCourseLocked
          ? "#EBF3F1"
          : "linear-gradient(113.57deg, #00AE7E 0.77%, #05566F 99.3%)",
        boxShadow: "0px 0px 20px 0px #00000014",
        borderRadius: "20px",
      }}
    >
      <img
        src={course?.image_url}
        alt=""
        width="100%"
        style={{ maxHeight: "290px" }}
      />

      <Box
        my={1.5}
        display="flex"
        alignItems="center"
        flexDirection={is780To1280 ? "column" : "row"}
        justifyContent="space-between"
        dir="rtl"
        gap={is780To1280 ? 1 : 0}
      >
        <Box
          display="flex"
          flexDirection="row"
          alignItems="center"
          backgroundColor={isCourseLocked ? "#fff" : "#389692"}
          p={1}
          sx={{
            width: is780To1280 ? "100%" : "auto",
            paddingX: is780To1280 ? 0 : 1.7,
            borderRadius: "4px",
          }}
        >
          <TheatersIcon
            sx={{
              color: isCourseLocked ? "#0D7F61" : "#fff",
              fontSize: "18px",
            }}
          />
          <Typography
            mr={0.7}
            variant="subtitle2"
            fontWeight="600"
            fontSize="9px"
            color={isCourseLocked ? "#222222" : "#fff"}
          >
            {course?.no_of_activities} نشاط
          </Typography>
        </Box>
      </Box>
      <Typography
        variant="h4"
        color={!isCourseLocked ? "#fff" : "#222222"}
        sx={{
          fontWeight: "600",
          fontSize: "18px",
          fontFamily: "El Messiri",
        }}
      >
        {course?.course_name}
      </Typography>

      <Stack direction="row" alignItems="center">
        <Box sx={{ position: "relative" }}>
          <CircularProgress
            variant="determinate"
            sx={{
              color: !isCourseLocked ? "#3B8190" : "#D4E6E2",
            }}
            size={40}
            thickness={10}
            value={100}
          />
          <CircularProgress
            variant="determinate"
            disableShrink
            sx={{
              color: !isCourseLocked ? "#fff" : "primary",
              animationDuration: "550ms",
              position: "absolute",
              left: 0,
              [`& .${circularProgressClasses.circle}`]: {
                strokeLinecap: "round",
              },
            }}
            size={40}
            thickness={10}
            value={circularProgress}
          />
        </Box>
        <Typography
          mr={1}
          variant="p"
          fontSize="10px"
          fontWeight="500"
          color={!isCourseLocked ? "#fff" : "#838383"}
        >
          <span
            style={{
              color: !isCourseLocked ? "#fff" : "#056F52",
              fontWeight: "700",
              fontSize: "16px",
            }}
          >
            {circularProgress}%{" "}
          </span>
          الانتهاء من الدورة
        </Typography>
      </Stack>
      {circularProgress === 100 ? (
        <></>
      ) : (
        <Stack
          direction="row"
          alignItems="center"
          justifyContent="center"
          my={1}
        >
          <Button
            variant="contained"
            endIcon={
              isCourseLocked ? (
                <LockIcon
                  sx={{
                    marginRight: 0.9,
                    color: "#DFDFDF",
                    background: "#3B3B3B",
                    borderRadius: "30px",
                    padding: "5px",
                  }}
                />
              ) : (
                <KeyboardBackspaceIcon sx={{ marginRight: 0.7 }} />
              )
            }
            sx={{
              background: isCourseLocked ? "#DFDFDF" : "#fff",
              color: isCourseLocked ? "#3B3B3B" : "#0D7F61",
              boxShadow: "none",
              height: "44px",
              width: "100%",
              borderRadius: "8px",
              fontSize: "12px",
              fontWeight: isCourseLocked ? 600 : 800,
              "&:hover": {
                background: isCourseLocked ? "#DFDFDF" : "#fff",
              },
            }}
            onClick={() => handleCourseClick()}
          >
            {actionText()}
          </Button>
        </Stack>
      )}
    </Box>
  );
};

export default CoursesCard;

CoursesCard.propTypes = {
  course: PropTypes.any,
  user: PropTypes.any,
};
