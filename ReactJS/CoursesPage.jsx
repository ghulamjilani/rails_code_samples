import { useEffect, useState } from "react";
import { Box, Breadcrumbs, Grid, Stack, Typography, Link } from "@mui/material";
import { useSelector } from "react-redux";
import NavigateBeforeIcon from "@mui/icons-material/NavigateBefore";

import HeroBg from "../../assets/courseBanner.png";
import homeIcon from "../../assets/courses/home-icon.svg";
import { listCourses } from "../../api/courses";
import CoursesCard from "../../components/dashboard/employee/cards/CoursesCard";

// eslint-disable-next-line react/prop-types
export default function CoursesPage() {
  const [courses, setCourses] = useState([]);

  const user = useSelector((state) => state.auth.user);

  const fetchCourses = async () => {
    try {
      const response = await listCourses();
      setCourses(response.data);
    } catch (error) {
      console.log("Error: ", error);
    }
  };

  useEffect(() => {
    fetchCourses();
  }, []);

  const breadcrumbs = [
    <Link
      underline="hover"
      key="1"
      href="/"
      sx={{
        color: "#FFFFFF99",
        fontSize: "20px",
        fontWeight: "500",
        "&:hover": { color: "#FFFFFF99", textDecoration: "none" },
      }}
    >
      <img src={homeIcon} alt="home-icon" style={{ marginLeft: "8px" }} />
      الرئيسية
    </Link>,
    <Typography
      key="3"
      color="white"
      fontSize="20px"
      fontWeight="600"
      sx={{ textDecoration: "underline" }}
    >
      الدورات
    </Typography>,
  ];

  return (
    <>
      <Box
        sx={{
          backgroundImage: `url(${HeroBg})`,
          backgroundSize: "100% 100%",
          backgroundRepeat: "no-repeat",
          backgroundPosition: "center",
          textAlign: "center",
          py: { md: 1.5, xs: 1 },
        }}
      >
        <Typography
          variant="h2"
          lineHeight={{ xs: 4, md: 5.2 }}
          fontSize={{ xs: "32px", md: "60px" }}
          fontWeight={600}
          color={"#FFFFFF"}
        >
          الدورات
        </Typography>

        <Stack spacing={3} px={5} py={3}>
          <Breadcrumbs
            separator={
              <NavigateBeforeIcon
                fontSize="small"
                sx={{ color: "#FFFFFF99" }}
              />
            }
            aria-label="breadcrumb"
          >
            {breadcrumbs}
          </Breadcrumbs>
        </Stack>
      </Box>
      <Box mt={5} px={{ xs: 3, md: 4.1 }}>
        <Grid container spacing={3}>
          {courses.map((course, index) => (
            <Grid key={index} item xs={12} sm={6} md={4}>
              <CoursesCard course={course} user={user} />
            </Grid>
          ))}
        </Grid>
      </Box>
    </>
  );
}
