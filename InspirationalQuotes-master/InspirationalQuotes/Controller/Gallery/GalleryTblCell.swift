//
//  TblCell.swift
//  CustomTableCell
//
//  Created by Andrew Seeley on 6/10/2014.
//  Copyright (c) 2014 Seemu. All rights reserved.
//

import UIKit

class GalleryTblCell: UITableViewCell {
    
    @IBOutlet var quoteButton:UIButton!
    @IBOutlet var favButton:UIButton!
    @IBOutlet var lblAuthor:UILabel!
    @IBOutlet var viewBG:UIView!
    @IBOutlet var imgBackground: UIImageView!

      override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
