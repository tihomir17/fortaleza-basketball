import io
from datetime import datetime
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from typing import Dict, Any, List


class AnalyticsPDFExporter:
    """Service for exporting analytics data to PDF format."""

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        """Setup custom paragraph styles for the report."""
        # Title style
        self.title_style = ParagraphStyle(
            "CustomTitle",
            parent=self.styles["Heading1"],
            fontSize=24,
            spaceAfter=30,
            alignment=TA_CENTER,
            textColor=colors.darkblue,
        )

        # Section header style
        self.section_style = ParagraphStyle(
            "CustomSection",
            parent=self.styles["Heading2"],
            fontSize=16,
            spaceAfter=12,
            spaceBefore=20,
            textColor=colors.darkblue,
        )

        # Subsection style
        self.subsection_style = ParagraphStyle(
            "CustomSubsection",
            parent=self.styles["Heading3"],
            fontSize=14,
            spaceAfter=8,
            spaceBefore=12,
            textColor=colors.darkgreen,
        )

        # Normal text style
        self.normal_style = ParagraphStyle(
            "CustomNormal", parent=self.styles["Normal"], fontSize=10, spaceAfter=6
        )

        # Data style
        self.data_style = ParagraphStyle(
            "CustomData",
            parent=self.styles["Normal"],
            fontSize=9,
            spaceAfter=4,
            fontName="Courier",
        )

    def export_analytics_to_pdf(
        self, analytics_data: Dict[str, Any], filters_applied: Dict[str, Any]
    ) -> bytes:
        """
        Export analytics data to PDF format.

        Args:
            analytics_data: The analytics data from the service
            filters_applied: The filters that were applied to generate the data

        Returns:
            PDF content as bytes
        """
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=72,
            leftMargin=72,
            topMargin=72,
            bottomMargin=72,
        )

        story = []

        # Add title
        story.append(Paragraph("Basketball Analytics Report", self.title_style))
        story.append(Spacer(1, 20))

        # Add report metadata
        story.extend(self._create_report_metadata(filters_applied))
        story.append(Spacer(1, 20))

        # Add summary statistics
        if analytics_data.get("summary"):
            story.extend(self._create_summary_section(analytics_data["summary"]))
            story.append(Spacer(1, 20))

        # Add offensive analysis
        if analytics_data.get("offensive_analysis"):
            story.extend(
                self._create_offensive_analysis_section(
                    analytics_data["offensive_analysis"]
                )
            )
            story.append(Spacer(1, 20))

        # Add defensive analysis
        if analytics_data.get("defensive_analysis"):
            story.extend(
                self._create_defensive_analysis_section(
                    analytics_data["defensive_analysis"]
                )
            )
            story.append(Spacer(1, 20))

        # Add player analysis
        if analytics_data.get("player_analysis"):
            story.extend(
                self._create_player_analysis_section(analytics_data["player_analysis"])
            )
            story.append(Spacer(1, 20))

        # Add detailed breakdown
        if analytics_data.get("detailed_breakdown"):
            story.extend(
                self._create_detailed_breakdown_section(
                    analytics_data["detailed_breakdown"]
                )
            )

        # Build PDF
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()

    def _create_report_metadata(self, filters_applied: Dict[str, Any]) -> List:
        """Create report metadata section."""
        story = []

        story.append(Paragraph("Report Information", self.section_style))

        # Create metadata table
        metadata = [
            ["Generated Date", datetime.now().strftime("%Y-%m-%d %H:%M:%S")],
            [
                "Total Possessions Analyzed",
                str(filters_applied.get("total_possessions_analyzed", 0)),
            ],
        ]

        # Add filter information
        if filters_applied.get("team_id"):
            metadata.append(["Team Filter", f"Team ID: {filters_applied['team_id']}"])

        if filters_applied.get("quarter_filter"):
            metadata.append(
                ["Quarter Filter", f"Quarter {filters_applied['quarter_filter']}"]
            )

        if filters_applied.get("last_games"):
            metadata.append(
                ["Games Filter", f"Last {filters_applied['last_games']} games"]
            )

        if filters_applied.get("outcome_filter"):
            outcome_map = {"W": "Wins", "L": "Losses"}
            metadata.append(
                [
                    "Outcome Filter",
                    outcome_map.get(
                        filters_applied["outcome_filter"],
                        filters_applied["outcome_filter"],
                    ),
                ]
            )

        if filters_applied.get("home_away_filter"):
            metadata.append(["Location Filter", filters_applied["home_away_filter"]])

        # Create table
        table = Table(metadata, colWidths=[2 * inch, 3 * inch])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 10),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                    ("BACKGROUND", (0, 1), (-1, -1), colors.beige),
                    ("GRID", (0, 0), (-1, -1), 1, colors.black),
                ]
            )
        )

        story.append(table)
        return story

    def _create_summary_section(self, summary_data: Dict[str, Any]) -> List:
        """Create summary statistics section."""
        story = []

        story.append(Paragraph("Summary Statistics", self.section_style))

        # Create summary table
        summary_table_data = [
            ["Metric", "Value"],
            ["Total Possessions", str(summary_data.get("total_possessions", 0))],
            [
                "Offensive Possessions",
                str(summary_data.get("offensive_possessions", 0)),
            ],
            [
                "Defensive Possessions",
                str(summary_data.get("defensive_possessions", 0)),
            ],
            ["Total Points", str(summary_data.get("total_points", 0))],
            ["Offensive Points", str(summary_data.get("offensive_points", 0))],
            ["Defensive Points", str(summary_data.get("defensive_points", 0))],
            ["Offensive PPP", f"{summary_data.get('offensive_ppp', 0):.2f}"],
            ["Defensive PPP", f"{summary_data.get('defensive_ppp', 0):.2f}"],
            ["Total PPP", f"{summary_data.get('total_ppp', 0):.2f}"],
            [
                "Average Possession Time",
                f"{summary_data.get('avg_possession_time', 0):.1f}s",
            ],
        ]

        table = Table(summary_table_data, colWidths=[2.5 * inch, 1.5 * inch])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.darkblue),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 12),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                    ("BACKGROUND", (0, 1), (-1, -1), colors.lightblue),
                    ("GRID", (0, 0), (-1, -1), 1, colors.black),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ]
            )
        )

        story.append(table)
        return story

    def _create_offensive_analysis_section(
        self, offensive_data: Dict[str, Any]
    ) -> List:
        """Create offensive analysis section."""
        story = []

        story.append(Paragraph("Offensive Analysis", self.section_style))

        # PnR Analysis
        if offensive_data.get("pnr_analysis"):
            story.append(Paragraph("Pick & Roll Analysis", self.subsection_style))
            pnr = offensive_data["pnr_analysis"]
            pnr_data = [
                ["Metric", "Value"],
                ["Total PnR Possessions", str(pnr.get("total_pnr_possessions", 0))],
                ["PnR Points", str(pnr.get("pnr_points", 0))],
                ["PnR PPP", f"{pnr.get('pnr_ppp', 0):.2f}"],
            ]

            # Add PnR results if available
            if pnr.get("pnr_results"):
                for result_type, count in pnr["pnr_results"].items():
                    pnr_data.append([f"PnR {result_type.title()}", str(count)])

            story.append(self._create_data_table(pnr_data, colors.lightgreen))
            story.append(Spacer(1, 10))

        # Paint Touch Analysis
        if offensive_data.get("paint_touch_analysis"):
            story.append(Paragraph("Paint Touch Analysis", self.subsection_style))
            paint = offensive_data["paint_touch_analysis"]
            paint_data = [
                ["Metric", "Value"],
                ["Total Paint Touches", str(paint.get("total_paint_touches", 0))],
                ["Paint Touch Points", str(paint.get("paint_touch_points", 0))],
                ["Paint Touch PPP", f"{paint.get('paint_touch_ppp', 0):.2f}"],
            ]
            story.append(self._create_data_table(paint_data, colors.lightyellow))
            story.append(Spacer(1, 10))

        # Shot Time Analysis
        if offensive_data.get("shot_time_analysis"):
            story.append(Paragraph("Shot Time Analysis", self.subsection_style))
            shot_time = offensive_data["shot_time_analysis"]
            shot_time_data = [["Time Range", "Possessions", "Points", "PPP"]]

            for time_range, data in shot_time.items():
                shot_time_data.append(
                    [
                        time_range,
                        str(data.get("possessions", 0)),
                        str(data.get("points", 0)),
                        f"{data.get('ppp', 0):.2f}",
                    ]
                )

            story.append(self._create_data_table(shot_time_data, colors.lightcoral))
            story.append(Spacer(1, 10))

        return story

    def _create_defensive_analysis_section(
        self, defensive_data: Dict[str, Any]
    ) -> List:
        """Create defensive analysis section."""
        story = []

        story.append(Paragraph("Defensive Analysis", self.section_style))

        # PnR Defense
        if defensive_data.get("pnr_defense"):
            story.append(Paragraph("PnR Defense", self.subsection_style))
            pnr_def = defensive_data["pnr_defense"]
            pnr_def_data = [
                ["Metric", "Value"],
                ["Total PnR Defense", str(pnr_def.get("total_pnr_defense", 0))],
                ["Points Allowed", str(pnr_def.get("pnr_defense_points_allowed", 0))],
                ["PPP Allowed", f"{pnr_def.get('pnr_defense_ppp_allowed', 0):.2f}"],
            ]
            story.append(self._create_data_table(pnr_def_data, colors.lightpink))
            story.append(Spacer(1, 10))

        # Box Out Analysis
        if defensive_data.get("box_out_analysis"):
            story.append(Paragraph("Box Out Analysis", self.subsection_style))
            box_out = defensive_data["box_out_analysis"]
            box_out_data = [
                ["Metric", "Value"],
                ["Total Box Outs", str(box_out.get("total_box_outs", 0))],
                ["Points Allowed", str(box_out.get("box_out_points_allowed", 0))],
                ["PPP Allowed", f"{box_out.get('box_out_ppp_allowed', 0):.2f}"],
            ]
            story.append(self._create_data_table(box_out_data, colors.lightsteelblue))
            story.append(Spacer(1, 10))

        return story

    def _create_player_analysis_section(self, player_data: Dict[str, Any]) -> List:
        """Create player analysis section."""
        story = []

        story.append(Paragraph("Player Performance Analysis", self.section_style))
        story.append(
            Paragraph(
                f"Minimum Possessions Threshold: {player_data.get('min_possessions_threshold', 0)}+",
                self.normal_style,
            )
        )

        if player_data.get("players"):
            story.append(Paragraph("Player Statistics", self.subsection_style))

            # Create player table
            player_table_data = [
                ["Player", "Possessions", "Points", "PPP", "Offensive PPP"]
            ]

            for player_id, player_stats in player_data["players"].items():
                player_table_data.append(
                    [
                        player_stats.get("player_name", "Unknown"),
                        str(player_stats.get("possessions", 0)),
                        str(player_stats.get("points", 0)),
                        f"{player_stats.get('ppp', 0):.2f}",
                        f"{player_stats.get('offensive_ppp', 0):.2f}",
                    ]
                )

            story.append(self._create_data_table(player_table_data, colors.lightcyan))

        return story

    def _create_detailed_breakdown_section(
        self, breakdown_data: Dict[str, Any]
    ) -> List:
        """Create detailed breakdown section."""
        story = []

        story.append(Paragraph("Detailed Breakdown", self.section_style))

        # Quarter Breakdown
        if breakdown_data.get("quarter_breakdown"):
            story.append(Paragraph("Quarter Breakdown", self.subsection_style))
            quarter_data = [["Quarter", "Possessions", "Points", "PPP"]]

            for quarter, stats in breakdown_data["quarter_breakdown"].items():
                quarter_data.append(
                    [
                        quarter,
                        str(stats.get("possessions", 0)),
                        str(stats.get("points", 0)),
                        f"{stats.get('ppp', 0):.2f}",
                    ]
                )

            story.append(self._create_data_table(quarter_data, colors.lightgrey))
            story.append(Spacer(1, 10))

        # Home/Away Breakdown
        if breakdown_data.get("home_away_breakdown"):
            story.append(Paragraph("Home/Away Breakdown", self.subsection_style))
            home_away_data = [["Location", "Possessions", "Points", "PPP"]]

            for location, stats in breakdown_data["home_away_breakdown"].items():
                home_away_data.append(
                    [
                        location,
                        str(stats.get("possessions", 0)),
                        str(stats.get("points", 0)),
                        f"{stats.get('ppp', 0):.2f}",
                    ]
                )

            story.append(
                self._create_data_table(home_away_data, colors.lightgoldenrodyellow)
            )

        return story

    def _create_data_table(
        self, data: List[List[str]], background_color: colors.Color
    ) -> Table:
        """Create a styled data table."""
        table = Table(data, colWidths=[1.5 * inch] * len(data[0]))
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.darkblue),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 10),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                    ("BACKGROUND", (0, 1), (-1, -1), background_color),
                    ("GRID", (0, 0), (-1, -1), 1, colors.black),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ]
            )
        )
        return table
