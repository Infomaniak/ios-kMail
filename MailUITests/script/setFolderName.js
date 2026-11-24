/*
 Infomaniak SwissTransfer - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const d = new Date()
const pad = (n) => String(n).padStart(2, '0')

output.folderName = 'UITestMobile-Folder-'
  + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate())
  + '-' + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds())
