import { Button } from "@mui/material";
import ExcelJS from "exceljs";
import { saveAs } from "file-saver";
import PropTypes from "prop-types";

import DownloadIcon from "@mui/icons-material/Download";

export const ExcelExporter = ({ data }) => {
  const exportToExcel = async () => {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("ورقة1");
    worksheet.views = [{ rightToLeft: true }];

    const columns =
      data.length > 0
        ? Object.keys(data[0]).map((key) => ({
            header: key,
            key,
            width: 15,
          }))
        : [];

    worksheet.columns = columns;

    data.forEach((item) => {
      worksheet.addRow(item);
    });

    const headerRow = worksheet.getRow(1);
    headerRow.height = 35;
    headerRow.eachCell((cell) => {
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFD3D3D3" },
      };
      cell.font = { color: { argb: "FF000000" }, bold: true };
      cell.alignment = {
        wrapText: true,
        vertical: "middle",
        horizontal: "center",
      };
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" },
      };
    });

    worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
      if (rowNumber > 1) {
        row.eachCell({ includeEmpty: false }, (cell) => {
          cell.border = {
            top: { style: 'thin' },
            left: { style: 'thin' },
            bottom: { style: 'thin' },
            right: { style: 'thin' },
          };

          cell.alignment = {
            vertical: "middle",
            horizontal: "right",
          };
        });
      }
    });

    const buffer = await workbook.xlsx.writeBuffer();

    saveAs(new Blob([buffer]), "requests.xlsx");
  };

  return (
    <div className="App">
      <Button
        variant="contained"
        endIcon={<DownloadIcon sx={{ mr: 2 }} />}
        onClick={exportToExcel}
        sx={{ width: { xs: "100%", sm: "auto" } }}
      >
        تصدير كملف Excel
      </Button>
    </div>
  );
};

ExcelExporter.propTypes = {
  data: PropTypes.arrayOf(PropTypes.object).isRequired,
};
