    
    import UIKit
    
    class ActivityLogVC: UIViewController {
        
        //-----------------------------------------------------------------------
        // Variables
        //-----------------------------------------------------------------------
        
        @IBOutlet var menuButton:UIButton!
        @IBOutlet var backButton:UIButton!
        
        @IBOutlet var tableView: UITableView!
        //@IBOutlet var sectionHeaderView: UIView!
        //@IBOutlet var lblSectionHeader: UILabel!
        @IBOutlet var lblNoFav: UILabel!
        
        var favQuote : NSMutableArray = []
        var arrayColor : NSArray = ["#b95557","#ffffff","#0080ef","#ffee55","#fc7a3f","#a25d85","#808080","#41723d","#f571b5","#91685b"]
        
        
        //-----------------------------------------------------------------------
        
        // MARK: - View Methods
        
        //-----------------------------------------------------------------------
        
        override func viewDidLoad() {
            super.viewDidLoad()
            self.revealViewController().panGestureRecognizer().isEnabled=false
            
            self.tableView.contentInset = UIEdgeInsetsMake(15, 0, 0, 0)
            
            tableView.separatorColor=UIColor.clear
            tableView.separatorStyle=UITableViewCellSeparatorStyle.none
            
            // Register custom cell
            let nib = UINib(nibName: "ActivityTblCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "ActivityTblCell")
            
            self.navigationController?.isNavigationBarHidden=true
            
            if revealViewController() != nil {
                menuButton.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
                view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            }
            
        }
        
        //-----------------------------------------------------------------------
        
        override func viewWillAppear(_ animated: Bool) {
            loadData()
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            
            if(appdelegate.status==fromHome) {
                backButton.isHidden=false
                menuButton.isHidden=true
            }
            else {
                backButton.isHidden=true
                menuButton.isHidden=false
                
            }
        }
        
        override var preferredStatusBarStyle : UIStatusBarStyle {
            return .lightContent
        }
        
        //-----------------------------------------------------------------------
        
        func loadData() {
            favQuote.removeAllObjects()
            
            let del = (UIApplication.shared.delegate as! AppDelegate)
            
            let QuoteDB = FMDatabase(path: del.strDBpath as String)
            
            if (QuoteDB?.open())! {
                let querySQL = "SELECT * from Quote,Favorites where QuoteID==ID"
                
                let results:FMResultSet? = QuoteDB?.executeQuery(querySQL,
                                                                withArgumentsIn: nil)
                var found=false as Bool
                
                while results!.next() {
                    found=true
                    
                    var parameters = [String: AnyObject]()
                    
                    parameters = [
                        "ID":(results?.string(forColumn: "ID")!)! as AnyObject,
                        "QuoteText":(results?.string(forColumn: "QuoteText")!)! as AnyObject,
                        "QuoteAuthor":(results?.string(forColumn: "QuoteAuthor")!)! as AnyObject,
                        "ColorIndex":(results?.string(forColumn: "ColorIndex")!)! as AnyObject
                        
                    ]
                    
                    favQuote.add(parameters)
                }
                
                if(!found) {
                    lblNoFav.isHidden=false
                }
                else
                {
                    lblNoFav.isHidden=true
                }
                
                print(favQuote);
                
                QuoteDB?.close()
                tableView .reloadData()
            }
        }
        
        override var prefersStatusBarHidden : Bool {
            return true;
        }
        
        //-----------------------------------------------------------------------
        
        @IBAction func backTapped(_ sender:UIButton!)
        {
            self.navigationController?.popViewController(animated: true);
            //
            //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            //        var vc = storyboard.instantiateViewControllerWithIdentifier("KeyChainVC")
            //
            //        var rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
            //        rvc.pushFrontViewController(vc, animated: true)
        }
        
        //-----------------------------------------------------------------------
        
        @IBAction func statusfavTapped(_ sender:UIButton!)
        {
            let button = sender as UIButton
            let view = button.superview!
            let cell = view.superview as! ActivityTblCell
            
            let indexPath = tableView.indexPath(for: cell)
            // print("row %d",indexPath?.row)
            
            //let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            var parameters = [String: AnyObject]()
            parameters=favQuote.object(at: ((indexPath as NSIndexPath?)?.row)!) as! [String : AnyObject]
            
            let  quoteId=parameters["ID"] as! NSString
            
            let del = (UIApplication.shared.delegate as! AppDelegate)
            
            let QuoteDB = FMDatabase(path: del.strDBpath as String)
            
            if (QuoteDB?.open())! {
                let str = NSString(format:"delete from Favorites where QuoteID=%d", quoteId.integerValue)
                
                let result = QuoteDB?.executeUpdate(str as String, withArgumentsIn: nil)
                
                print(result)
            }
            
            QuoteDB?.close()
            loadData()
            
        }
        
        @IBAction func shareFavQuoteTapped(_ sender:UIButton!)
        {
            let button = sender as UIButton
            let view = button.superview!
            let cell = view.superview as! ActivityTblCell
            
            let indexPath = tableView.indexPath(for: cell)
            print("row %d",(indexPath as NSIndexPath?)?.row)
            
            let shareText = NSString(format:"Sharing the quote from Inspirational Quotes App :\n%@", (cell.quoteButton.titleLabel?.text)!)
            
            let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: [])
            present(vc, animated: true, completion: nil)
            
        }
        
        //-----------------------------------------------------------------------
        
        // MARK: - TableView Methods
        
        //-----------------------------------------------------------------------
        
        func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
            return 1
        }
        
        //----------------------------------------------------------------------------------------------------------------------------------------------
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return favQuote.count
        }
        
        //----------------------------------------------------------------------------------------------------------------------------------------------
        
        func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
            
            let cell=tableView.dequeueReusableCell(withIdentifier: "ActivityTblCell", for: indexPath) as! ActivityTblCell
            cell.selectionStyle=UITableViewCellSelectionStyle.none
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.clear
            cell.selectedBackgroundView = backgroundView
            
            var parameters = [String: AnyObject]()
            parameters=favQuote.object(at: (indexPath as NSIndexPath).row) as! [String : AnyObject]
            
            let strQuote=parameters["QuoteText"] as! String;
            let strAuthor=parameters["QuoteAuthor"] as! String;
            
            //rjm
            let strTemp = NSString(format:"%@\n- %@", strQuote,strAuthor)
            cell.quoteButton.setTitle(strTemp as String, for: UIControlState())
            
            //let colorIndex=parameters["ColorIndex"] as! NSString;
            
            //let coloridx=colorIndex.integerValue
            
            //   cell.lblAuthor.text=strAuthor
            
            //  cell.quoteButton.setTitle(strQuote, forState: .Normal)
            
            //let color1 = colorWithHexString(arrayColor.objectAtIndex(coloridx) as! NSString as String)
            //cell.viewBG.backgroundColor=color1
            
            cell.favButton .setImage(UIImage(named:"Dislike"), for: UIControlState())
            
            return cell
            
        }
        
        //----------------------------------------------------------------------------------------------------------------------------------------------
        
        // 5
        func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
            return 274
            
        }
        
        //----------------------------------------------------------------------------------------------------------------------------------------------
        
        // 4
        func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
            print("Row \((indexPath as NSIndexPath).row) selected")
            
            NSLog("selected : %d",(indexPath as NSIndexPath).row)
            
            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
            selectedCell.contentView.backgroundColor = UIColor.clear
            
        }
        
    }