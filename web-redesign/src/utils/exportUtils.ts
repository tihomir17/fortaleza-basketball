import jsPDF from 'jspdf'
import html2canvas from 'html2canvas'
import * as XLSX from 'xlsx'
import { saveAs } from 'file-saver'

// Types for export data
export interface ExportableData {
  [key: string]: any
}

export interface ExportOptions {
  filename?: string
  title?: string
  includeTimestamp?: boolean
  format?: 'pdf' | 'excel' | 'csv'
}

// PDF Export Functions
export const exportToPDF = async (
  elementId: string,
  options: ExportOptions = {}
): Promise<void> => {
  try {
    const element = document.getElementById(elementId)
    if (!element) {
      throw new Error(`Element with id "${elementId}" not found`)
    }

    const canvas = await html2canvas(element, {
      scale: 2,
      useCORS: true,
      allowTaint: true,
      backgroundColor: '#ffffff'
    })

    const imgData = canvas.toDataURL('image/png')
    const pdf = new jsPDF('p', 'mm', 'a4')
    
    const imgWidth = 210
    const pageHeight = 295
    const imgHeight = (canvas.height * imgWidth) / canvas.width
    let heightLeft = imgHeight

    let position = 0

    // Add title if provided
    if (options.title) {
      pdf.setFontSize(20)
      pdf.text(options.title, 20, 20)
      position = 30
    }

    // Add timestamp if requested
    if (options.includeTimestamp) {
      pdf.setFontSize(10)
      pdf.text(`Generated on: ${new Date().toLocaleString()}`, 20, position + 10)
      position += 20
    }

    pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
    heightLeft -= pageHeight

    while (heightLeft >= 0) {
      position = heightLeft - imgHeight
      pdf.addPage()
      pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
      heightLeft -= pageHeight
    }

    const filename = options.filename || `export_${Date.now()}.pdf`
    pdf.save(filename)
  } catch (error) {
    console.error('Error exporting to PDF:', error)
    throw error
  }
}

// Excel Export Functions
export const exportToExcel = (
  data: ExportableData[],
  options: ExportOptions = {}
): void => {
  try {
    const worksheet = XLSX.utils.json_to_sheet(data)
    const workbook = XLSX.utils.book_new()
    
    // Add metadata if provided
    if (options.title) {
      const titleRow = [['Fortaleza Analytics Export', options.title]]
      const titleSheet = XLSX.utils.aoa_to_sheet(titleRow)
      XLSX.utils.book_append_sheet(workbook, titleSheet, 'Info')
    }

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Data')

    // Add timestamp if requested
    if (options.includeTimestamp) {
      const timestampData = [
        { 'Generated on': new Date().toLocaleString() },
        { 'Total records': data.length }
      ]
      const timestampSheet = XLSX.utils.json_to_sheet(timestampData)
      XLSX.utils.book_append_sheet(workbook, timestampSheet, 'Metadata')
    }

    const filename = options.filename || `export_${Date.now()}.xlsx`
    XLSX.writeFile(workbook, filename)
  } catch (error) {
    console.error('Error exporting to Excel:', error)
    throw error
  }
}

// CSV Export Functions
export const exportToCSV = (
  data: ExportableData[],
  options: ExportOptions = {}
): void => {
  try {
    if (data.length === 0) {
      throw new Error('No data to export')
    }

    const headers = Object.keys(data[0])
    const csvContent = [
      headers.join(','),
      ...data.map(row => 
        headers.map(header => {
          const value = row[header]
          // Escape commas and quotes in CSV
          if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
            return `"${value.replace(/"/g, '""')}"`
          }
          return value
        }).join(',')
      )
    ].join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const filename = options.filename || `export_${Date.now()}.csv`
    saveAs(blob, filename)
  } catch (error) {
    console.error('Error exporting to CSV:', error)
    throw error
  }
}

// Generic Export Function
export const exportData = (
  data: ExportableData[],
  format: 'pdf' | 'excel' | 'csv',
  options: ExportOptions = {}
): void => {
  switch (format) {
    case 'excel':
      exportToExcel(data, options)
      break
    case 'csv':
      exportToCSV(data, options)
      break
    case 'pdf':
      // For PDF, we need to create a temporary element with the data
      createPDFFromData(data, options)
      break
    default:
      throw new Error(`Unsupported export format: ${format}`)
  }
}

// Helper function to create PDF from data
const createPDFFromData = (data: ExportableData[], options: ExportOptions = {}): void => {
  try {
    const pdf = new jsPDF('p', 'mm', 'a4')
    let yPosition = 20

    // Add title
    if (options.title) {
      pdf.setFontSize(20)
      pdf.text(options.title, 20, yPosition)
      yPosition += 15
    }

    // Add timestamp
    if (options.includeTimestamp) {
      pdf.setFontSize(10)
      pdf.text(`Generated on: ${new Date().toLocaleString()}`, 20, yPosition)
      yPosition += 10
    }

    // Add data
    if (data.length > 0) {
      const headers = Object.keys(data[0])
      const colWidth = 180 / headers.length

      // Headers
      pdf.setFontSize(12)
      pdf.setFont('helvetica', 'bold')
      headers.forEach((header, index) => {
        pdf.text(header, 20 + (index * colWidth), yPosition)
      })
      yPosition += 10

      // Data rows
      pdf.setFont('helvetica', 'normal')
      pdf.setFontSize(10)
      
      data.forEach((row, _rowIndex) => {
        if (yPosition > 280) {
          pdf.addPage()
          yPosition = 20
        }

        headers.forEach((header, colIndex) => {
          const value = String(row[header] || '')
          pdf.text(value, 20 + (colIndex * colWidth), yPosition)
        })
        yPosition += 8
      })
    }

    const filename = options.filename || `export_${Date.now()}.pdf`
    pdf.save(filename)
  } catch (error) {
    console.error('Error creating PDF from data:', error)
    throw error
  }
}

// Specialized export functions for different data types
export const exportGames = (games: any[], format: 'pdf' | 'excel' | 'csv' = 'excel') => {
  const formattedGames = games.map(game => ({
    'Game ID': game.id,
    'Date': new Date(game.date).toLocaleDateString(),
    'Time': new Date(game.date).toLocaleTimeString(),
    'Home Team': game.home_team_name,
    'Away Team': game.away_team_name,
    'Location': game.location || 'TBD',
    'Status': game.status,
    'Home Score': game.home_score || 0,
    'Away Score': game.away_score || 0,
    'Result': game.result || 'TBD',
    'Season': game.season || 'Current',
    'Notes': game.notes || ''
  }))

  exportData(formattedGames, format, {
    title: 'Games Export',
    filename: `games_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
    includeTimestamp: true
  })
}

export const exportPlayers = (players: any[], format: 'pdf' | 'excel' | 'csv' = 'excel') => {
  const formattedPlayers = players.map(player => ({
    'Player ID': player.id,
    'Name': player.name,
    'Number': player.number,
    'Position': player.position,
    'Height': player.height || 'N/A',
    'Weight': player.weight || 'N/A',
    'Age': player.age || 'N/A',
    'Team': player.team_name || 'N/A',
    'Status': player.status || 'Active',
    'Jersey Number': player.jersey_number || 'N/A',
    'Date Joined': player.date_joined ? new Date(player.date_joined).toLocaleDateString() : 'N/A'
  }))

  exportData(formattedPlayers, format, {
    title: 'Players Export',
    filename: `players_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
    includeTimestamp: true
  })
}

export const exportTeams = (teams: any[], format: 'pdf' | 'excel' | 'csv' = 'excel') => {
  const formattedTeams = teams.map(team => ({
    'Team ID': team.id,
    'Name': team.name,
    'City': team.city || 'N/A',
    'State': team.state || 'N/A',
    'League': team.league || 'N/A',
    'Division': team.division || 'N/A',
    'Coach': team.coach || 'N/A',
    'Founded': team.founded || 'N/A',
    'Home Arena': team.home_arena || 'N/A',
    'Website': team.website || 'N/A',
    'Status': team.status || 'Active'
  }))

  exportData(formattedTeams, format, {
    title: 'Teams Export',
    filename: `teams_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
    includeTimestamp: true
  })
}

export const exportAnalytics = (analyticsData: any[], format: 'pdf' | 'excel' | 'csv' = 'excel') => {
  const formattedAnalytics = analyticsData.map(data => ({
    'Metric': data.metric,
    'Value': data.value,
    'Period': data.period,
    'Team': data.team || 'All Teams',
    'Player': data.player || 'All Players',
    'Game': data.game || 'All Games',
    'Date': data.date ? new Date(data.date).toLocaleDateString() : 'N/A',
    'Category': data.category || 'General'
  }))

  exportData(formattedAnalytics, format, {
    title: 'Analytics Export',
    filename: `analytics_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
    includeTimestamp: true
  })
}
