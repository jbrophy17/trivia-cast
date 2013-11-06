//
//  TVCCastDiscoveryViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCCastDiscoveryViewController.h"
#import "TVCAppDelegate.h"
#import <GCKFramework/GCKFramework.h>
#import "TVCLobbyViewController.h"
#import "TVCSettingsViewController.h"
#import "TVCDataSource.h"

@interface TVCCastDiscoveryViewController () <GCKDeviceManagerListener>
{
    NSMutableArray *_devices;
    GCKDevice *_selectedDevice;
}

@end

@implementation TVCCastDiscoveryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"view did load Discovery");
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"view will appear Discovery");
    _devices = [appDelegate.deviceManager.devices mutableCopy];
    [appDelegate.deviceManager addListener:self];
    [appDelegate.deviceManager startScan];
    [self.tableView reloadData];
    NSLog(@"devices: %i",[_devices count]);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"view did appear Discovery");
    NSString *userName = [appDelegate userName];
    if (!userName || [userName length] == 0) {
        
        [self performSegueWithIdentifier:@"Settings" sender:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [appDelegate.deviceManager stopScan];
    [appDelegate.deviceManager removeListener:self];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)refresh:(id)sender {
    [appDelegate.deviceManager startScan];
}

-(void) initialLaunch {
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}

- (void)timerFired:(NSTimer *)timer
{
    if ([_devices count] == 1) {
        [appDelegate setDataSource:[[TVCDataSource alloc] initWithDevice:[_devices objectAtIndex:0]]];
        UIStoryboard *storyboard = self.storyboard;
        TVCLobbyViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"lobbyViewController"];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    const GCKDevice *device = [_devices objectAtIndex:(NSUInteger)indexPath.row];
    cell.textLabel.text = device.friendlyName;
    cell.detailTextLabel.text = device.ipAddress;
    
    return cell;
}

#pragma mark - GCKDeviceManagerListener

- (void)scanStarted {
}

- (void)scanStopped {
    // No-op
    NSLog(@"devices: %i",[_devices count]);
}

- (void)deviceDidComeOnline:(GCKDevice *)device {
    if (![_devices containsObject:device]) {
        [_devices addObject:device];
        [self.tableView reloadData];
    }
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    [_devices removeObject:device];
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DeviceSelected"]) {
       // TVCLobbyViewController *viewController = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [appDelegate setDataSource:[[TVCDataSource alloc] initWithDevice:[_devices objectAtIndex:indexPath.row]]];
        //viewController.device = [_devices objectAtIndex:indexPath.row];
    }
}

@end
